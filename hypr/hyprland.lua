-- Hyprland configuration for Nvidia RTX 4070 Super.
-- Native Lua configuration for Hyprland 0.56+.

require("colors")

local terminal = os.getenv("TERMINAL")
local super = "SUPER"

-- Keep GTK applications on the generated Base16 theme. This must be set by
-- Hyprland itself so directly launched applications (including Firefox) do not
-- inherit a stale login-shell GTK_THEME override.
hl.env("GTK_THEME", "QuickshellSync")

local function glass_mode_enabled()
    local settings = io.open(os.getenv("HOME") .. "/.config/quickshell/shell-settings.json", "r")
    if not settings then
        return false
    end
    local contents = settings:read("*a")
    settings:close()
    return contents:match('"glassMode"%s*:%s*true') ~= nil
end

-- Monitor configuration
hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@180",
    position = "0x0",
    scale = 1,
})

-- Applications and startup. The event only fires once when Hyprland starts,
-- so saving/reloading this file does not rerun these commands.
hl.on("hyprland.start", function()
    hl.exec_cmd("xset r rate 700 25")
    hl.exec_cmd("~/Scripts/breaks.py")
    hl.exec_cmd('hyprctl setcursor "oreo_black_cursors" 24')
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("theme-daemon")
    hl.exec_cmd("qs -d")
    hl.exec_cmd("kdeconnect-indicator &")
end)

-- General, decoration, layout, input, cursor, and miscellaneous settings
hl.config({
    general = {
        gaps_in = 2,
        gaps_out = 8,
        gaps_workspaces = 0,
        resize_on_border = true,
        layout = "dwindle",
    },
    decoration = {
        shadow = {
            enabled = false,
            color = "rgba(00000055)",
            color_inactive = "rgba(00000055)",
            range = 30,
            scale = 1,
        },
        active_opacity = 1,
        inactive_opacity = 1,
        dim_inactive = true,
        dim_strength = 0.1,
        blur = {
            enabled = true,
            size = 5,
            passes = 3,
            ignore_opacity = true,
            new_optimizations = true,
            xray = false,
        },
    },
    animations = {
        enabled = true,
    },
    dwindle = {
        preserve_split = true,
        force_split = 2,
        default_split_ratio = 1,
    },
    master = {
        new_status = "master",
    },
    xwayland = {
        force_zero_scaling = true,
    },
    cursor = {
        persistent_warps = true,
        warp_on_change_workspace = true,
        zoom_factor = 1,
    },
    debug = {
        error_position = 1,
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        font_family = "Adwaita Mono Nerd Font",
        layers_hog_keyboard_focus = true,
        animate_manual_resizes = true,
        animate_mouse_windowdragging = true,
        disable_splash_rendering = true,
        enable_swallow = false,
        focus_on_activate = false,
        initial_workspace_tracking = true,
        close_special_on_empty = true,
    },
    input = {
        kb_layout = "us",
        repeat_rate = 45,
        repeat_delay = 300,
        follow_mouse = 1,
        sensitivity = -0.55,
        accel_profile = "flat",
    },
})

-- Animation curves and leaves
hl.curve("myBezier", {
    type = "bezier",
    points = { { 0.05, 0.9 }, { 0.1, 1.05 } },
})
hl.curve("smoothOut", {
    type = "bezier",
    points = { { 0.36, 0 }, { 0.66, -0.56 } },
})
hl.curve("smoothIn", {
    type = "bezier",
    points = { { 0.25, 1 }, { 0.5, 1 } },
})

hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "myBezier", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "smoothOut" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, bezier = "myBezier", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "smoothIn" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "smoothIn", style = "slidevert" })

-- Key bindings
hl.bind(super .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(super .. " + SHIFT + return", hl.dsp.exec_cmd("alacritty"))
hl.bind(super .. " + Q", hl.dsp.window.close())
hl.bind(super .. " + W", hl.dsp.exec_cmd("~/Scripts/waybar_restart.sh"))
hl.bind(super .. " + W", hl.dsp.exec_cmd("nix run ~/Codes/ollama"))
hl.bind(super .. " + period", hl.dsp.exec_cmd("emote"))
hl.bind(super .. " + X", hl.dsp.exit())
hl.bind(super .. " + SHIFT + X", hl.dsp.exec_cmd("poweroff"))
hl.bind(super .. " + SHIFT + R", hl.dsp.exec_cmd("reboot"))
hl.bind(super .. " + S", hl.dsp.window.float({ action = "toggle" }))
hl.bind("ALT + SHIFT + space", hl.dsp.exec_cmd("~/Scripts/run"))
hl.bind("ALT + space", hl.dsp.exec_cmd("qs ipc call shell toggleLauncher"))
hl.bind(super .. " + ALT + S", hl.dsp.exec_cmd("qs ipc call shell toggleSidePanel"))
hl.bind(super .. " + ALT + Q", hl.dsp.exec_cmd("qs ipc call shell toggleControls"))
hl.bind(super .. " + ALT + T", hl.dsp.exec_cmd("qs ipc call shell toggleTodo"))
hl.bind(super .. " + SHIFT + CTRL + L", hl.dsp.exec_cmd(os.getenv("HOME") .. "/.config/quickshell/scripts/lock-screen"), { description = "Lock screen" })
hl.bind(super .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(super .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(super .. " + SHIFT + S", hl.dsp.window.pseudo())
hl.bind(super .. " + T", hl.dsp.layout("togglesplit"), { description = "$d toggle split" })

hl.bind(super .. " + CTRL + h", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind(super .. " + CTRL + l", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
hl.bind(super .. " + CTRL + k", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind(super .. " + CTRL + j", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })

hl.bind(super .. " + SHIFT + h", hl.dsp.window.move({ direction = "l" }), { repeating = true })
hl.bind(super .. " + SHIFT + l", hl.dsp.window.move({ direction = "r" }), { repeating = true })
hl.bind(super .. " + SHIFT + k", hl.dsp.window.move({ direction = "u" }), { repeating = true })
hl.bind(super .. " + SHIFT + j", hl.dsp.window.move({ direction = "d" }))

hl.bind(super .. " + A", hl.dsp.exec_cmd("/home/chilly/Scripts/notifs.sh date && /home/chilly/Scripts/notifs.sh time"))
hl.bind(super .. " + escape", hl.dsp.exec_cmd("hyprctl kill"), { transparent = true })

hl.bind(super .. " + h", hl.dsp.focus({ direction = "l" }))
hl.bind(super .. " + l", hl.dsp.focus({ direction = "r" }))
hl.bind(super .. " + k", hl.dsp.focus({ direction = "u" }))
hl.bind(super .. " + j", hl.dsp.focus({ direction = "d" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(super .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(super .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(super .. " + u", hl.dsp.focus({ workspace = 1 }))
hl.bind(super .. " + i", hl.dsp.focus({ workspace = 2 }))
hl.bind(super .. " + o", hl.dsp.focus({ workspace = 3 }))

hl.bind(super .. " + e", hl.dsp.exec_cmd("unset DISPLAY && emacsclient -c"))
hl.bind(super .. " + SHIFT + e", hl.dsp.exec_cmd("~/Scripts/emacsRestart.sh"))
hl.bind(super .. " + SHIFT + c", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind("Print", hl.dsp.exec_cmd("qs ipc call shell toggleScreenshot"))
hl.bind(super .. " + Print", hl.dsp.exec_cmd("qs ipc call shell screenshot window save"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("qs ipc call shell screenshot output save"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("qs ipc call shell screenshot region lens"))

hl.bind(super .. " + g", hl.dsp.group.toggle())
hl.bind(super .. " + tab", hl.dsp.group.next())
hl.bind(super .. " + SHIFT + b", hl.dsp.exec_cmd("firefox"))

hl.bind(super .. " + space", hl.dsp.workspace.toggle_special("scratchpad"), { repeating = true })
hl.bind(super .. " + SHIFT + space", hl.dsp.window.move({ workspace = "special:scratchpad" }))
hl.bind(super .. " + d", hl.dsp.workspace.toggle_special("dashboard"), { repeating = true })
hl.bind(super .. " + SHIFT + d", hl.dsp.window.move({ workspace = "special:dashboard" }))

hl.bind(super .. " + p", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(super .. " + n", hl.dsp.focus({ workspace = "e+1" }))

hl.bind(super .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(super .. " + SHIFT + mouse:272", hl.dsp.window.resize(), { mouse = true })

local repeating = { repeating = true }
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("qs ipc call shell changeVolume 5"), repeating)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("qs ipc call shell changeVolume -- -5"), repeating)
hl.bind(super .. " + UP", hl.dsp.exec_cmd("qs ipc call shell changeVolume 5"), repeating)
hl.bind(super .. " + DOWN", hl.dsp.exec_cmd("qs ipc call shell changeVolume -- -5"), repeating)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))
hl.bind(super .. " + LEFT", hl.dsp.exec_cmd("qs ipc call shell changeBrightness -- -5"), repeating)
hl.bind(super .. " + RIGHT", hl.dsp.exec_cmd("qs ipc call shell changeBrightness 5"), repeating)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs ipc call shell changeBrightness 5"), repeating)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("qs ipc call shell changeBrightness -- -5"), repeating)

-- Window rules
hl.window_rule({
    name = "ueberzug-float",
    match = { class = "ueberzugpp_.*" },
    float = true,
})

hl.window_rule({
    name = "ueberzug-nofocus",
    match = { class = "ueberzugpp_.*" },
    no_initial_focus = true,
})

-- Quickshell glass surfaces. The rule remains declared in the native Lua
-- configuration so reloading Hyprland updates all existing layer surfaces.
local quickshellGlassRule = hl.layer_rule({
    name = "quickshell-glass",
    match = { namespace = "^quickshell$" },
    blur = true,
    -- Retain blur through near-clear QML pixels in Transparent glass mode.
    ignore_alpha = 0.001,
})
quickshellGlassRule:set_enabled(glass_mode_enabled())

-- Desktop constellation widgets stay visually container-free. Their QML layer
-- exposes only near-zero-alpha geometry, so this rule blurs the wallpaper in
-- those regions without adding a colored surface.
hl.layer_rule({
    name = "desktop-constellation-blur",
    match = { namespace = "^desktop-constellation$" },
    blur = true,
    ignore_alpha = 0.001,
})

