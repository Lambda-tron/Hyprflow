-- Hyprflow — Hyprland Lua config (converted from hyprland.conf)
-- Faithful 1:1 translation of the classic config. Hyprland loads this file in
-- preference to hyprland.conf; delete it to fall back to the .conf instantly.
-- Docs: https://wiki.hypr.land/configuring/

------------------
---- MONITORS ----
------------------

-- Catch-all fallback for any unlisted output.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- eDP-1 on the left (0,0 is HDMI-A-2 below), HDMI-A-2 to its left.
hl.monitor({ output = "eDP-1",    mode = "1920x1080@60", position = "1920x0", scale = 1 })
hl.monitor({ output = "HDMI-A-2", mode = "1920x1080@60", position = "0x0",    scale = 1 })


-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("hypridle")
    hl.exec_cmd("mako")
    hl.exec_cmd("~/.local/bin/battery-warning.sh")
    hl.exec_cmd("hyprctl switchxkblayout all 1")  -- start on Swedish (index 1 of us,se,jp)
    hl.exec_cmd("waybar")
    hl.exec_cmd("nm-applet --indicator")
end)


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "foot"
local fileManager = "plume"
local menu        = "rofi -show drun"


----------------
---- LAYERS ----
----------------

hl.layer_rule({ match = { namespace = "foot" }, blur = true })
hl.layer_rule({ match = { namespace = "rofi" }, blur = true })


---------------
---- CURSOR ---
---------------

hl.config({
    cursor = {
        no_hardware_cursors = true,
        inactive_timeout    = 0,
    },
})


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 4,

        col = {
            active_border   = "rgba(cba6f7ff)",  -- was rgba(203,166,247,1.0)
            inactive_border = "rgba(585b70ff)",  -- was rgba(88,91,112,1.0)
        },

        resize_on_border = false,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 6,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = false,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled    = true,
            size       = 6,     -- main cost factor -> keep low (5-7 is sweet spot)
            passes     = 1,     -- 1 = big performance gain
            noise      = 0.02,  -- subtle grain to hide low blur quality
            contrast   = 1.0,
            brightness = 1.0,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Bezier curves (match the classic config).
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        mouse_move_enables_dpms  = true,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us,se,jp",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- workspace_swipe was disabled (commented) in the classic config, so no gesture here.

hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "ALT"

hl.bind(mainMod .. " + SHIFT + RETURN", hl.dsp.exec_cmd("foot"))
hl.bind(mainMod .. " + T",              hl.dsp.exec_cmd("~/.config/hypr/scripts/notes.sh"))
hl.bind(mainMod .. " + B",              hl.dsp.exec_cmd("killall -SIGUSR1 waybar"))
hl.bind(mainMod .. " + SHIFT + C",      hl.dsp.window.close())
hl.bind(mainMod .. " + M",              hl.dsp.exit())
hl.bind(mainMod .. " + E",              hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V",              hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P",              hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + I",              hl.dsp.window.pseudo({ action = "toggle" }))
hl.bind(mainMod .. " + J",              hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + RETURN",         hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod .. " + HOME",           hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind(mainMod .. " + SHIFT + L",      hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + SHIFT + SPACE",  hl.dsp.exec_cmd("~/.config/hypr/scripts/cycle-kb-layout.sh"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Move windows with mainMod + SHIFT + arrow keys
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Screenshot monitor 2 (Print) -> file
hl.bind("Print", hl.dsp.exec_cmd("grim -o HDMI-A-2 ~/Pictures/monitor2-$(date +%Y-%m-%d_%H-%M-%S).png"), { locked = true })

-- Switch / move-to workspaces with mainMod + [0-9] (0 = workspace 10)
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Numpad -> switch workspaces
hl.bind(mainMod .. " + KP_END",   hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + KP_DOWN",  hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + KP_NEXT",  hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + KP_LEFT",  hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + KP_BEGIN", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + KP_RIGHT", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + KP_HOME",  hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + KP_UP",    hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + KP_PRIOR", hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + KP_INSERT",hl.dsp.focus({ workspace = 10 }))

-- Numpad -> move window to workspace
hl.bind(mainMod .. " + SHIFT + KP_END",   hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + SHIFT + KP_DOWN",  hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + SHIFT + KP_NEXT",  hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + SHIFT + KP_LEFT",  hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + SHIFT + KP_BEGIN", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + SHIFT + KP_RIGHT", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + SHIFT + KP_HOME",  hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + KP_UP",    hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + SHIFT + KP_PRIOR", hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + SHIFT + KP_INSERT",hl.dsp.window.move({ workspace = 10 }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB drag
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Resize active window with mainMod + CTRL + arrows
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0,   y = -20, relative = true }))
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0,   y = 20,  relative = true }))
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -20, y = 0,   relative = true }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 20,  y = 0,   relative = true }))

-- Night light toggle
hl.bind(mainMod .. " + F9",  hl.dsp.exec_cmd("wlsunset -T 6500"))
hl.bind(mainMod .. " + F10", hl.dsp.exec_cmd("pkill wlsunset"))

-- Laptop multimedia keys (locked = works while locked, repeating = key repeat)
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh up"),            { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh down"),          { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh mute"),          { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),    { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                   { locked = true, repeating = true })

-- Media control (playerctl)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Lock on lid close
hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("hyprlock"), { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Floating notes terminal (Alt+T) — small centered rectangle
hl.window_rule({
    name  = "notes-float",
    match = { class = "notes-float" },
    float  = true,
    center = true,
})

-- Assign workspaces 1-4 to DP-1, 5-8 to HDMI-A-2 (unchanged from the .conf)
hl.workspace_rule({ workspace = "1", monitor = "DP-1" })
hl.workspace_rule({ workspace = "2", monitor = "DP-1" })
hl.workspace_rule({ workspace = "3", monitor = "DP-1" })
hl.workspace_rule({ workspace = "4", monitor = "DP-1" })
hl.workspace_rule({ workspace = "5", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "7", monitor = "HDMI-A-2" })
hl.workspace_rule({ workspace = "8", monitor = "HDMI-A-2" })
