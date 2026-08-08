#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_NAME="${SUDO_USER:-${USER}}"
USER_HOME="$(eval echo "~${USER_NAME}")"

info()  { printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
error() { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*"; }

run_as_user() {
  if [[ "$(id -un)" == "$USER_NAME" ]]; then
    "$@"
  else
    sudo -u "$USER_NAME" "$@"
  fi
}

ensure_not_root_only_home() {
  if [[ ! -d "$USER_HOME" ]]; then
    error "Could not resolve home directory for user '$USER_NAME'."
    exit 1
  fi
}

install_base_dependencies() {
  info "Refreshing package database..."
  sudo pacman -Sy --noconfirm

  info "Installing base tools needed for setup..."
  sudo pacman -S --needed --noconfirm base-devel git curl wget unzip
}

install_yay() {
  if command -v yay >/dev/null 2>&1; then
    info "yay is already installed."
    return
  fi

  info "Installing yay..."
  local tmpdir
  tmpdir="$(mktemp -d)"
  run_as_user git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
  (
    cd "$tmpdir/yay"
    run_as_user makepkg -si --noconfirm
  )
  rm -rf "$tmpdir"
}

install_packages() {
  info "Installing packages from the repo list plus config dependencies..."

  local packages=(
    gnome-themes-extra
    gnome-tweaks
    hyprshot
    hyprlock
    mako
    libnotify
    zsh
    rofi
    firefox
    dolphin
    kitty
    hyprland
    wayland
    pipewire
    pipewire-pulse
    pipewire-alsa
    wireplumber
    pavucontrol
    brightnessctl
    qt5ct
    transmission-gtk
    openssh
    kate
    hypridle
    bluez
    bluez-utils
    blueman
    nemo
    grim
    playerctl
    wlsunset
    upower
    papirus-icon-theme
    wmctrl
  )

  sudo pacman -S --needed --noconfirm "${packages[@]}"
}

configure_services() {
  info "Enabling Bluetooth service..."
  sudo systemctl enable --now bluetooth.service || warn "Could not enable bluetooth.service"
}

apply_gsettings() {
  if ! command -v gsettings >/dev/null 2>&1; then
    warn "gsettings is not available. Skipping GTK dark theme setup."
    return
  fi

  info "Applying GTK dark theme preferences..."
  run_as_user dbus-launch gsettings set org.gnome.desktop.interface color-scheme prefer-dark || warn "Could not set color-scheme"
  run_as_user dbus-launch gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark || warn "Could not set gtk-theme"

  warn "Set 'Legacy Applications' to 'Adwaita-dark' in GNOME Tweaks if it does not apply automatically."
}

install_oh_my_zsh() {
  if [[ -d "$USER_HOME/.oh-my-zsh" ]]; then
    info "Oh My Zsh is already installed."
  else
    info "Installing Oh My Zsh..."
    local tmp_script
    tmp_script="$(mktemp)"
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$tmp_script"
    chmod +x "$tmp_script"
    run_as_user env RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$tmp_script" --unattended
    rm -f "$tmp_script"
  fi

  if [[ "$(getent passwd "$USER_NAME" | cut -d: -f7)" != "$(command -v zsh)" ]]; then
    info "Changing default shell to zsh for $USER_NAME..."
    sudo chsh -s "$(command -v zsh)" "$USER_NAME" || warn "Could not change default shell automatically"
  fi
}
configure_zsh() {
  info "Configuring .zshrc..."

  local zshrc="$USER_HOME/.zshrc"

  run_as_user touch "$zshrc"

  if run_as_user grep -q '^ZSH_THEME=' "$zshrc"; then
    run_as_user sed -i 's/^ZSH_THEME=.*/ZSH_THEME="daveverwer"/' "$zshrc"
  else
    printf '\nZSH_THEME="daveverwer"\n' | run_as_user tee -a "$zshrc" >/dev/null
  fi

  if ! run_as_user grep -q 'exec start-hyprland' "$zshrc"; then
    cat <<'EOF' | run_as_user tee -a "$zshrc" >/dev/null

# Auto start Hyprland on login (TTY only)
if [[ -z "$DISPLAY" ]] && [[ "$(tty)" == "/dev/tty1" ]]; then
  exec start-hyprland
fi
EOF
  fi
}


copy_configs() {
  info "Copying configs to $USER_HOME/.config ..."

  run_as_user mkdir -p "$USER_HOME/.config"

  run_as_user cp -r "$REPO_DIR/hypr" "$USER_HOME/.config/"
  run_as_user cp -r "$REPO_DIR/kitty" "$USER_HOME/.config/"
  run_as_user cp -r "$REPO_DIR/rofi" "$USER_HOME/.config/"

  sudo chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/.config"
}

install_scripts() {
  info "Installing user scripts to $USER_HOME/.local/bin ..."

  run_as_user mkdir -p "$USER_HOME/.local/bin"
  run_as_user cp "$REPO_DIR/bin/battery-warning.sh" "$USER_HOME/.local/bin/battery-warning.sh"
  run_as_user chmod +x "$USER_HOME/.local/bin/battery-warning.sh"

  sudo chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/.local/bin"
}
print_done() {
  cat <<MSG

Setup complete.

Installed:
- yay
- Oh My Zsh
- Hyprland desktop packages
- Kitty / Rofi / Hypr* configs
- GTK dark theme preferences
- battery-warning.sh -> ~/.local/bin/

Config locations:
- ~/.config/hypr/
- ~/.config/kitty/
- ~/.config/rofi/
- ~/.local/bin/

You may want to reboot or log out and back in before launching Hyprland.
MSG
}

main() {
  ensure_not_root_only_home
  install_base_dependencies
  install_yay
  install_packages
  configure_services
  apply_gsettings
  install_oh_my_zsh
  configure_zsh
  copy_configs
  install_scripts
  print_done
}

main "$@"

