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
  info "Updating the system..."
  sudo pacman -Syu --noconfirm

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
    # Compositor + session
    hyprland
    wayland
    hyprlock
    hypridle
    hyprshot
    grim
    # Bar, launcher, notifications, terminal
    waybar
    rofi
    mako
    libnotify
    foot
    # Audio stack (PipeWire + WirePlumber; wpctl / pw-play come from these)
    pipewire
    pipewire-pulse
    pipewire-alsa
    wireplumber
    # Hardware controls used by keybinds / scripts
    brightnessctl
    playerctl
    wlsunset
    upower
    lm_sensors
    # Helpers the config scripts rely on
    jq
    vim
    network-manager-applet
    wmctrl
    # Shell, theming, fonts
    zsh
    qt5ct
    gnome-themes-extra
    gnome-tweaks
    papirus-icon-theme
    ttf-jetbrains-mono-nerd
    noto-fonts-cjk            # Japanese / Chinese / Korean text
    # Networking (NetworkManager replaces iwd)
    networkmanager
    wpa_supplicant
    # Sound card firmware (Intel SOF laptops)
    sof-firmware
    # Portals (screen share, file dialogs) + Qt Wayland support
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    qt5-wayland
    qt6-wayland
    # Rust toolchain + libs to build plume / audiopanel
    rust
    gtk4
    libpulse
    # Dev tools (Flutter desktop/Android, web, database)
    clang
    cmake
    ninja
    pkgconf
    gtk3
    xz
    mesa-utils
    jdk17-openjdk
    android-tools
    scrcpy
    nodejs
    npm
    postgresql
    # Misc apps
    firefox
    chromium
    discord
    obs-studio
    kate
    transmission-gtk
    openssh
  )

  sudo pacman -S --needed --noconfirm "${packages[@]}"
}

install_aur_packages() {
  info "Installing AUR packages (claude-code, vesktop)..."
  run_as_user yay -S --needed --noconfirm claude-code vesktop
}

enable_services() {
  info "Enabling NetworkManager (and disabling iwd)..."
  sudo systemctl disable --now iwd 2>/dev/null || true
  sudo systemctl enable --now NetworkManager

  info "Enabling PipeWire user services..."
  run_as_user systemctl --user enable pipewire pipewire-pulse wireplumber || warn "Enable PipeWire after first login"

  if ! sudo test -f /var/lib/postgres/data/PG_VERSION; then
    info "Initialising PostgreSQL data directory..."
    sudo -u postgres initdb -D /var/lib/postgres/data
  fi
  sudo systemctl enable --now postgresql
}

install_flutter() {
  if [[ -x "$USER_HOME/.flutter/flutter/bin/flutter" ]]; then
    info "Flutter is already installed."
    return
  fi
  info "Installing Flutter (stable) to ~/.flutter/flutter ..."
  run_as_user mkdir -p "$USER_HOME/.flutter"
  run_as_user git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$USER_HOME/.flutter/flutter"
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
  info "Installing .zshrc and .zshenv (existing ones are backed up as *.bak)..."
  local f
  for f in .zshrc .zshenv; do
    if [[ -f "$USER_HOME/$f" ]]; then
      run_as_user cp "$USER_HOME/$f" "$USER_HOME/$f.bak"
    fi
    run_as_user cp "$REPO_DIR/home/$f" "$USER_HOME/$f"
  done
}


copy_configs() {
  info "Copying configs to $USER_HOME/.config ..."

  run_as_user mkdir -p "$USER_HOME/.config"

  run_as_user cp -r "$REPO_DIR/hypr"   "$USER_HOME/.config/"
  run_as_user cp -r "$REPO_DIR/rofi"   "$USER_HOME/.config/"
  run_as_user cp -r "$REPO_DIR/waybar" "$USER_HOME/.config/"
  run_as_user cp -r "$REPO_DIR/mako"   "$USER_HOME/.config/"
  run_as_user cp -r "$REPO_DIR/foot"   "$USER_HOME/.config/"
  run_as_user cp -r "$REPO_DIR/xdg-desktop-portal" "$USER_HOME/.config/"
  run_as_user cp "$REPO_DIR/home/mimeapps.list" "$USER_HOME/.config/mimeapps.list"

  sudo chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/.config"
}

# Binaries the configs call but that are NOT installed here (you install these
# yourself). We only check and print a short note about each missing one.
warn_missing_optional() {
  info "Checking for optional helper binaries..."

  # name|short description of what it does / where it's used
  local optional=(
    "plume|file manager + file picker (Alt+E, Firefox open/save dialogs)"
    "audiopanel|audio mixer panel (Waybar volume click / mic right-click)"
  )

  local missing=()
  local entry name desc
  for entry in "${optional[@]}"; do
    name="${entry%%|*}"
    desc="${entry#*|}"
    if ! run_as_user command -v "$name" >/dev/null 2>&1; then
      missing+=("  - ${name}: ${desc}")
    fi
  done

  if (( ${#missing[@]} )); then
    warn "The following helpers are not installed. Install them separately:"
    printf '%s\n' "${missing[@]}"
    warn "See 'Own apps' at the end of this output for the commands."
  else
    info "All optional helper binaries are present."
  fi
}

install_scripts() {
  info "Installing user scripts to $USER_HOME/.local/bin ..."

  run_as_user mkdir -p "$USER_HOME/.local/bin"
  run_as_user cp "$REPO_DIR/bin/battery-warning.sh" "$USER_HOME/.local/bin/battery-warning.sh"
  run_as_user chmod +x "$USER_HOME/.local/bin/battery-warning.sh"

  sudo chown -R "$USER_NAME":"$USER_NAME" "$USER_HOME/.local/bin"
}
print_done() {
  cat <<'MSG'

Setup complete.

Installed:
- yay, Oh My Zsh, your .zshrc / .zshenv
- Hyprland desktop (Waybar, Rofi, Mako, foot, PipeWire, portals)
- Fonts incl. Japanese (noto-fonts-cjk)
- Apps: Firefox, Chromium, Discord, Vesktop, OBS, Kate, Transmission, Claude Code
- Dev: Rust, Flutter (~/.flutter), JDK 17, Node/npm, PostgreSQL, scrcpy
- Configs: ~/.config/{hypr,waybar,rofi,mako,foot,xdg-desktop-portal}

Own apps (private repos: put your SSH key in ~/.ssh first):

  plume (file manager + Firefox file picker):
    git clone git@github.com:Lambda-tron/plume.git ~/plume && ~/plume/portal/install.sh
    (also makes Firefox use plume for open/save dialogs automatically)

  audiopanel (audio mixer):
    git clone git@github.com:Lambda-tron/audiopanel.git ~/audiopanel && cd ~/audiopanel \
      && cargo install --path . \
      && install -Dm644 packaging/audiopanel.desktop ~/.local/share/applications/audiopanel.desktop

Manual: Android SDK (for Flutter Android builds) goes in ~/.Android/Sdk,
then run: flutter doctor --android-licenses

Reboot, log in on tty1 and Hyprland starts automatically.
MSG
}

main() {
  ensure_not_root_only_home
  install_base_dependencies
  install_yay
  install_packages
  install_aur_packages
  enable_services
  install_flutter
  apply_gsettings
  install_oh_my_zsh
  configure_zsh
  copy_configs
  install_scripts
  warn_missing_optional
  print_done
}

main "$@"

