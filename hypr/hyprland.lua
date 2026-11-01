-- ~/.config/hypr/hyprland.lua
-- Colours come from matugen (~/.config/hypr/colors.lua, regenerated on every wallpaper change)

---@module 'hl'

--###########################
--## MATUGEN COLOURS ########
--###########################

local ok, colors = pcall(require, "colors")
if not ok or type(colors) ~= "table" then
    -- first boot / matugen hasn't run yet: neutral fallback so the config still loads
    colors = {
        primary = "0xffffb4a6", secondary = "0xffe7bdb5", tertiary = "0xffddc48c",
        surface = "0xff1a1110", surface_variant = "0xff534340", outline_variant = "0xff534340",
        shadow = "0xff000000", scrim = "0xff000000",
    }
end

-- "0xffRRGGBB" string -> number, optionally with a new alpha (0..1)
local function col(name, alpha)
    local n = tonumber(colors[name]) or 0xff000000
    if alpha then
        n = (n % 16777216) + math.floor(alpha * 255) * 16777216
    end
    return n
end

--###############
--## MONITORS ###
--###############
require("monitors")

hl.monitor({ output = "eDP-1",    cm = "srgb", sdr_eotf = "gamma22" })
hl.monitor({ output = "HDMI-A-1", cm = "srgb", sdr_eotf = "gamma22" })

hl.config({ render = { cm_enabled = true, cm_sdr_eotf = "gamma22" } })
hl.config({ quirks = { skip_non_kms_dmabuf_formats = false } })

--############################
--## ENVIRONMENT VARIABLES ###
--############################
hl.env("XCURSOR_SIZE", 24)
hl.env("HYPRCURSOR_SIZE", 24)
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")

--####################
--## LOOK AND FEEL ###
--####################
hl.config({
    general = {
        gaps_in          = 4,
        gaps_out         = 8,
        border_size      = 1,
        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
        ["col.active_border"]   = col("primary", 0.9),
        ["col.inactive_border"] = col("outline_variant", 0.35),
    },
})

hl.config({
    decoration = {
        rounding         = 10,
        rounding_power   = 2,      -- plain circular corners: they line up cleanly with a thin border
        active_opacity   = 1.0,
        inactive_opacity = 1.0,     -- <1.0 forces blur on EVERY inactive window (expensive); dimming below does the focus cue instead
        dim_inactive     = true,
        dim_strength     = 0.10,
        shadow = {
            enabled      = true,
            range        = 12,
            render_power = 3,
            color        = col("shadow", 0.40),
        },
        blur = {
            enabled   = true,
            size      = 8,
            passes    = 2,           -- 2 passes @ size 8 looks ~ like 3 @ 7 for a third less GPU work
            noise     = 0.015,
            contrast  = 0.95,
            brightness = 0.9,
            vibrancy  = 0.17,
            popups    = true,
        },
    },
})

-- Animations ───────────────────────────────────────────────────
-- Custom curves / styles are wrapped in pcall so a syntax difference on your
-- Hyprland build can never stop the config from loading (a failed style falls back to none).
local function curve(name, p1, p2)
    return pcall(hl.curve, name, { type = "bezier", points = { p1, p2 } }) and name or "default"
end
local quint   = curve("easeOutQuint",   { 0.23, 1 },    { 0.32, 1 })     -- fast start, long soft landing
local quick   = curve("quick",          { 0.15, 0 },    { 0.1, 1 })
local linear2 = curve("almostLinear",   { 0.5, 0.5 },   { 0.75, 1.0 })   -- good for fades
local spring  = curve("overshoot",      { 0.05, 0.9 },  { 0.1, 1.05 })   -- tiny bounce on open

local function anim(leaf, speed, bezier, style)
    local spec = { leaf = leaf, enabled = true, speed = speed, bezier = bezier }
    if style then
        spec.style = style
        if pcall(hl.animation, spec) then return end
        spec.style = nil
    end
    pcall(hl.animation, spec)
end

hl.config({ animations = { enabled = true } })
anim("global",           5,   quint)
anim("windowsIn",        4.2, spring,  "popin 86%")
anim("windowsOut",       3.0, quint,   "popin 90%")
anim("windowsMove",      4.5, quint)
anim("border",           6,   quint)
anim("fadeIn",           3.0, linear2)
anim("fadeOut",          2.4, linear2)
anim("fade",             3.0, quick)
anim("fadeLayersIn",     3.0, linear2)
anim("fadeLayersOut",    2.4, linear2)
anim("layersIn",         4.0, quint,   "fade")
anim("layersOut",        3.0, quint,   "fade")
anim("workspaces",       5.0, quint,   "slidefade 15%")
anim("specialWorkspace", 5.0, quint,   "slidefadevert 20%")

hl.config({ dwindle = { preserve_split = true } })
hl.config({ master  = { new_status = "master" } })
hl.config({
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,
    },
})

-- Layer rules ────────────────────────────────────────────────
-- These two already worked for you:
hl.layer_rule({ name = "eww-panel-animation", match = { namespace = "eww-panel" }, animation = "slide right" })
hl.layer_rule({ name = "rofi-animation",      match = { namespace = "rofi" },      animation = "slide bottom" })

-- Frosted-glass blur behind the shell components (guarded, see note above)
local function blur_layer(name, namespace)
    pcall(hl.layer_rule, {
        name = name .. "-blur",
        match = { namespace = namespace },
        blur = true,
        ignore_alpha = 0.25,
    })
end
blur_layer("waybar",       "waybar")
blur_layer("rofi",         "rofi")
blur_layer("eww",          "eww-panel")
blur_layer("swaync-cc",    "swaync-control-center")
blur_layer("swaync-notif", "swaync-notification-window")

--############
--## INPUT ###
--############
hl.config({
    input = {
        kb_layout    = "us",
        kb_variant   = "",
        kb_model     = "",
        kb_options   = "",
        kb_rules     = "",
        follow_mouse = 1,
        sensitivity  = 0,
        touchpad = { natural_scroll = true },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })

--##################
--## KEYBINDINGS ###
--##################
local mainMod = "SUPER"

-- Core applications & window operations
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("alacritty"))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("dolphin"))
hl.bind(mainMod .. " + V", hl.dsp.window.float())
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("eww open --toggle control_panel"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("rofi -i -show drun"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))

-- Wallpaper + theme (matugen)
hl.bind(mainMod .. " + W",         hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/wallpaper.sh"))
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/wallpaper-picker.sh"))

-- Move focus
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Workspaces 1-10 (switch / move window)
for i = 1, 10 do
    local key = tostring(i % 10)
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Mouse drag / resize
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume (wpctl) with OSD via swaync
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd([[wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ && notify-send -e -t 1500 -h string:x-canonical-private-synchronous:volume_notif -h int:value:"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')" -i "audio-volume-high" "Volume" "Increasing volume..." -a "System"]]), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd([[wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && notify-send -e -t 1500 -h string:x-canonical-private-synchronous:volume_notif -h int:value:"$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100)}')" -i "audio-volume-low" "Volume" "Decreasing volume..." -a "System"]]), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd([[wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && [ "$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -o 'MUTED')" = "MUTED" ] && notify-send -e -t 1500 -h string:x-canonical-private-synchronous:volume_notif -i "audio-volume-muted" "Muted" "Audio output silenced" -a "System" || notify-send -e -t 1500 -h string:x-canonical-private-synchronous:volume_notif -i "audio-volume-high" "Unmuted" "Audio output active" -a "System"]]), { locked = true })

-- Brightness (brightnessctl)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd([[brightnessctl set 5%+ && notify-send -e -t 1500 -h string:x-canonical-private-synchronous:brightness_notif -h int:value:"$(brightnessctl -m | awk -F, '{print substr($4, 1, length($4)-1)}')" -i "display-brightness" "Brightness" "Increasing brightness..." -a "System"]]), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd([[brightnessctl set 5%- && notify-send -e -t 1500 -h string:x-canonical-private-synchronous:brightness_notif -h int:value:"$(brightnessctl -m | awk -F, '{print substr($4, 1, length($4)-1)}')" -i "display-brightness" "Brightness" "Decreasing brightness..." -a "System"]]), { repeating = true })

-- Media
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Screenshots
hl.bind("Print",                  hl.dsp.exec_cmd("grimblast --notify --freeze copysave area"))
hl.bind(mainMod .. " + Print",    hl.dsp.exec_cmd("grimblast --notify copysave output"))

--#############################
--## WINDOWS AND WORKSPACES ###
--#############################
hl.window_rule({ name = "suppress-maximize-events", match = { class = ".*" }, suppress_event = "maximize" })

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = { 20, "monitor_h-120" },
    float = true,
})

-- Small utility windows float by default
hl.window_rule({
    name  = "float-utilities",
    match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|nm-connection-editor|blueman-manager|org.gnome.Calculator)$" },
    float = true,
})

--#################
--## AUTOSTART ####
--#################
hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon &")
    hl.exec_cmd("sleep 1 && awww restore &")      -- bring back the last wallpaper
    hl.exec_cmd("eww kill; eww daemon &")
    hl.exec_cmd("swaync &")
    hl.exec_cmd("waybar &")
    hl.exec_cmd("nm-applet &")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("nmcli device disconnect wlan0; nmcli device connect wlan0")
    hl.exec_cmd("blueman-applet")
    hl.exec_cmd("otd-daemon &")
end)
