--------------------------------------------------------------------------------
-- Hyprland configuration (Lua)
--
-- Target: Hyprland >= 0.55 (written against 0.57.1; API checked against the
--         bundled stubs in /usr/share/hypr/stubs/hl.meta.lua and the wiki).
--
-- The legacy ~/.config/hypr/hyprland.conf is kept as a reference only:
-- since 0.55 Hyprland prefers hyprland.lua when both files are present.
--------------------------------------------------------------------------------


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "wezterm"
local fileManager = "nautilus"
local menu        = "rofi -show drun"
local mainMod     = "SUPER"

-- Bind helpers. A description is attached to every bind, so `hyprctl binds`
-- (and cheatsheet generators) can show what each shortcut does.
local function withDescription(opts, description)
    local merged = {}
    for k, v in pairs(opts or {}) do merged[k] = v end
    merged.description = description
    return merged
end

-- Bind with the main modifier prepended; extra modifiers go into `keys`.
local function bind(keys, dispatcher, description, opts)
    return hl.bind(mainMod .. " + " .. keys, dispatcher, withDescription(opts, description))
end

-- Bind without the main modifier (Print, XF86 keys, ...).
local function rawBind(keys, dispatcher, description, opts)
    return hl.bind(keys, dispatcher, withDescription(opts, description))
end


------------------
---- MONITORS ----
------------------

-- Hyprland has no built-in "internal"/"external" concept: monitor rules are
-- keyed by output name. Modes and scaling are left to the display:
--   * mode  = "preferred" uses the EDID-recommended mode (resolution + refresh)
--   * scale = "auto"      derives the scale from the panel's PPI
--                         (2x above 200 PPI, 1.5x above 140 PPI, otherwise 1x)
-- Outputs named eDP-*/LVDS-*/DSI-* are treated as the laptop panel and any
-- other connected output as external by the profile switcher below.
--
-- One fallback rule covers every output, including hot-plugged monitors.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Optional per-output overrides (not required for auto-detection):
-- Pin the 4K-capable LG to 4K with crisp 2x scaling:
--   hl.monitor({ output = "HDMI-A-4", mode = "highres", scale = 2 })
-- Or keep it at 1080p120 while still auto-scaling:
--   hl.monitor({ output = "HDMI-A-4", mode = "1920x1080@120", scale = "auto" })

-- Monitor helpers ---------------------------------------------------------
local function allMonitors()
    return hl.get_monitors({ all = true })
end

local function isInternal(name)
    return name:match("^eDP%-") ~= nil
        or name:match("^LVDS%-") ~= nil
        or name:match("^DSI%-") ~= nil
end

-- First internal panel (found even while disabled).
local function internalMonitor()
    for _, monitor in ipairs(allMonitors()) do
        if isInternal(monitor.name) then return monitor end
    end
end

-- First external output, preferring an enabled one but falling back to a
-- disabled one so profiles can bring it back. Only one external is handled.
local function externalMonitor()
    local disabled
    for _, monitor in ipairs(allMonitors()) do
        if not isInternal(monitor.name) then
            if monitor.enabled then return monitor end
            disabled = disabled or monitor
        end
    end
    return disabled
end

-- Re-applying the mirror after the panel is enabled is needed when Duplicate
-- is chosen from External only: a mirror rule that references a disabled
-- monitor is ignored by Hyprland.
local duplicateTimer

local function applyDuplicate()
    local laptop, external = internalMonitor(), externalMonitor()
    if not laptop or not external then return end

    -- Both outputs run at scale 1 so the clone is a 1:1 pixel copy; the panel
    -- normally uses 1.5x and the copy would otherwise be upscaled and blurry.
    hl.monitor({ output = laptop.name, disabled = false, position = "0x0", scale = 1 })
    hl.monitor({
        output = external.name,
        mirror = laptop.name,
        disabled = false,
        position = "0x0",
        scale = 1,
    })
end

-- Runtime monitor profiles, cycled with SUPER + SHIFT + M:
--   Extend -> External only -> Duplicate -> Laptop only
-- Profiles needing an output that is not connected are skipped.
-- hl.monitor() merges into the existing rule for the same output, so each
-- profile only changes the fields it cares about. Runtime changes are
-- forgotten on config reload/restart, which restores the layout above.
local monitorProfiles = {
    {
        name = "Extend",
        canApply = function()
            return internalMonitor() ~= nil or externalMonitor() ~= nil
        end,
        apply = function()
            local laptop, external = internalMonitor(), externalMonitor()
            if laptop then
                hl.monitor({ output = laptop.name, disabled = false, position = "0x0", scale = "auto" })
            end
            if external then
                hl.monitor({ output = external.name, mirror = "", disabled = false, position = "auto", scale = "auto" })
            end
        end,
    },
    {
        name = "External only",
        canApply = function()
            return externalMonitor() ~= nil
        end,
        apply = function()
            local laptop, external = internalMonitor(), externalMonitor()
            if laptop then
                hl.monitor({ output = laptop.name, disabled = true })
            end
            if external then
                hl.monitor({ output = external.name, mirror = "", disabled = false, position = "0x0", scale = "auto" })
            end
        end,
    },
    {
        name = "Duplicate",
        canApply = function()
            return internalMonitor() ~= nil and externalMonitor() ~= nil
        end,
        apply = function()
            applyDuplicate()
            if duplicateTimer then duplicateTimer:set_enabled(false) end
            duplicateTimer = hl.timer(applyDuplicate, { timeout = 800, type = "oneshot" })
        end,
    },
    {
        name = "Laptop only",
        canApply = function()
            return internalMonitor() ~= nil
        end,
        apply = function()
            local laptop, external = internalMonitor(), externalMonitor()
            if external then
                hl.monitor({ output = external.name, mirror = "", disabled = true })
            end
            if laptop then
                hl.monitor({ output = laptop.name, disabled = false, position = "0x0", scale = "auto" })
            end
        end,
    },
}

-- The chosen profile is persisted here and re-applied after config reloads,
-- restarts and monitor reconnects. Runtime hl.monitor() changes live only in
-- Hyprland's in-memory rule list, so without this a reload rebuilds the rules
-- from this file and silently reverts to "Extend".
local stateHome       = os.getenv("XDG_STATE_HOME") or ((os.getenv("HOME") or "/home/bhhoang") .. "/.local/state")
local profileStateFile = stateHome .. "/hypr-monitor-profile"

local function readSavedProfile()
    local handle = io.open(profileStateFile, "r")
    if not handle then return "Extend" end
    local name = handle:read("*l")
    handle:close()
    return name or "Extend"
end

local function saveProfile(name)
    pcall(function()
        local handle = assert(io.open(profileStateFile, "w"))
        handle:write(name, "\n")
        handle:close()
    end)
end

-- Entry points for the rofi picker. These are globals on purpose: they stay
-- available in Hyprland's Lua state, so both `hyprctl repl/eval` and the menu
-- script can call them.
function hyprMonitorProfilesAvailable()
    local names = {}
    for _, profile in ipairs(monitorProfiles) do
        if profile.canApply() then
            names[#names + 1] = profile.name
        end
    end
    return names
end

-- Infer the active profile from the live monitor state.
function hyprDetectMonitorProfile()
    local laptop, external = internalMonitor(), externalMonitor()

    if not laptop then return "Extend" end
    if not external then return "Laptop only" end
    if not laptop.enabled then return "External only" end
    if not external.enabled then return "Laptop only" end
    if external.is_mirror then return "Duplicate" end
    return "Extend"
end

-- opts.silent  : don't show a notification (used for automatic re-apply)
-- opts.persist : false = don't overwrite the saved choice (used for fallbacks)

-- Guards against monitor.added/config.reloaded handlers re-applying the saved
-- profile while an explicit profile change is still running.
local applyingProfile = false
local settleTimer
local focusTimer

-- Put focus back on the laptop panel when it is on, otherwise on the external.
local function focusPrimary()
    local laptop = internalMonitor()
    if laptop and laptop.enabled then
        hl.dispatch(hl.dsp.focus({ monitor = laptop.name }))
        return
    end
    local external = externalMonitor()
    if external and external.enabled then
        hl.dispatch(hl.dsp.focus({ monitor = external.name }))
    end
end

function hyprSetMonitorProfile(name, opts)
    opts = opts or {}

    for _, profile in ipairs(monitorProfiles) do
        if profile.name:lower() == tostring(name or ""):lower() then
            if not profile.canApply() then
                if not opts.silent then
                    hl.notification.create({ text = "Monitor: " .. name .. " is not available", timeout = 2000, icon = "error" })
                end
                return false
            end

            -- Persist before applying: enabling outputs fires monitor.added,
            -- and that handler must see the new choice, not the previous one.
            if opts.persist ~= false then
                saveProfile(profile.name)
            end

            -- Cancel a pending Duplicate re-apply before switching profiles.
            if duplicateTimer then duplicateTimer:set_enabled(false) end

            applyingProfile = true
            profile.apply()

            -- Enabling or rescaling an output emits monitor.added. Ignore
            -- those events briefly, otherwise they re-apply a stale profile
            -- and the layout churns.
            if settleTimer then settleTimer:set_enabled(false) end
            settleTimer = hl.timer(function()
                applyingProfile = false
            end, { timeout = 1200, type = "oneshot" })

            -- Enabling a monitor can move focus to it; put it back once the
            -- layout has settled.
            focusPrimary()
            if focusTimer then focusTimer:set_enabled(false) end
            focusTimer = hl.timer(focusPrimary, { timeout = 800, type = "oneshot" })

            if not opts.silent then
                hl.notification.create({ text = "Monitor: " .. name, timeout = 1500, icon = "ok" })
            end
            return true
        end
    end

    if not opts.silent then
        hl.notification.create({ text = "Unknown monitor profile: " .. tostring(name), timeout = 2000, icon = "error" })
    end
    return false
end

-- Restore the saved profile. If it cannot run right now (for example the
-- external was unplugged), fall back safely without overwriting the choice.
local function applySavedProfile()
    if applyingProfile then return end

    if not internalMonitor() and not externalMonitor() then
        return -- monitors are not initialized yet
    end

    if hyprSetMonitorProfile(readSavedProfile(), { silent = true }) then
        return
    end

    local fallback
    if externalMonitor() then
        fallback = "External only"
    elseif internalMonitor() then
        fallback = "Laptop only"
    else
        fallback = "Extend"
    end
    hyprSetMonitorProfile(fallback, { silent = true, persist = false })
end

hl.on("hyprland.start", applySavedProfile)
hl.on("config.reloaded", applySavedProfile)
hl.on("monitor.added", applySavedProfile)

-- Pick a profile from a rofi menu (the script runs outside the compositor,
-- so opening it never blocks input).
bind("SHIFT + M", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/monitor-menu.sh"), "Choose monitor mode")


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("GTK_THEME", "Adwaita-dark")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Qt theming plugins are not installed (neither qt5ct nor qt6ct); leaving this
-- unset avoids pointless warnings. Uncomment after installing one of them:
-- hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- NVIDIA variables from the old config, kept for reference:
-- hl.env("LIBVA_DRIVER_NAME", "nvidia")
-- hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")


-------------------
---- AUTOSTART ----
-------------------

-- `hyprland.start` fires once at startup, so this behaves like exec-once.
-- hl.exec_cmd() is asynchronous: no trailing `&` is needed.
hl.on("hyprland.start", function()
    hl.exec_cmd("fcitx5 -d")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    -- electronmail is no longer installed on this machine:
    -- hl.exec_cmd("electronmail")
end)


-----------------------
----- PERMISSIONS -----
-----------------------

-- Disabled by default. Enabling it without an allow rule would make `grim`
-- capture a black image, so keep it off unless you also add the rules below.
-- hl.config({ ecosystem = { enforce_permissions = true } })
-- hl.permission({ binary = "/usr/bin/grim", type = "screencopy", mode = "allow" })
-- hl.permission({ binary = "/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", type = "screencopy", mode = "allow" })
-- hl.permission({ binary = "/usr/bin/hyprpm", type = "plugin", mode = "allow" })


-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in          = 5,
        gaps_out         = 20,
        border_size      = 2,
        col = {
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        layout           = "dwindle",
        allow_tearing    = false,
        resize_on_border = false,
    },

    decoration = {
        rounding = 5,
        blur = {
            enabled = true,
            size    = 3,
            passes  = 1,
        },
        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    misc = {
        -- No wallpaper daemon is installed, so keep a neutral built-in one.
        force_default_wallpaper = 1,
    },

    cursor = {
        -- Modern equivalent of the legacy env WLR_NO_HARDWARE_CURSOR=1.
        no_hardware_cursors = 1,
    },

    input = {
        kb_layout    = "us",
        follow_mouse = 2,          -- cursor focus detached from keyboard focus
        sensitivity  = 1.0,        -- -1.0 .. 1.0; 0 = no change
        touchpad = {
            natural_scroll = true,
        },
    },

    gestures = {
        -- Replaces workspace_swipe = on / workspace_swipe_fingers = 4.
        workspace_swipe_distance   = 300,
        workspace_swipe_create_new = false,
        workspace_swipe_forever    = true,
    },
})

-- The swipe itself is now a gesture binding instead of a config flag.
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })

-- Custom curve + the animation set from the old config. Unmentioned leaves
-- inherit Hyprland's defaults.
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })

hl.animation({ leaf = "windows",    enabled = true, speed = 7,  bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8,  bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 6,  bezier = "default" })


---------------------
---- KEYBINDINGS ----
---------------------

-- Programs ---------------------------------------------------------------
bind("Q", hl.dsp.exec_cmd(terminal),    "Open terminal")
bind("E", hl.dsp.exec_cmd(fileManager), "Open file manager")
bind("R", hl.dsp.exec_cmd(menu),        "Open application launcher")
bind("SHIFT + R", hl.dsp.exec_cmd("rofi -show window"), "Switch window (rofi)")
bind("C", hl.dsp.window.close(),        "Close active window")

-- Window state -----------------------------------------------------------
bind("V", hl.dsp.window.float({ action = "toggle" }), "Toggle floating")
bind("P", hl.dsp.window.pseudo(),                    "Toggle pseudotiling (dwindle)")
bind("J", hl.dsp.layout("togglesplit"),              "Toggle split direction (dwindle)")
bind("SHIFT + P", hl.dsp.window.pin({ action = "toggle" }), "Pin/unpin window")
bind("F", hl.dsp.window.fullscreen({ action = "toggle" }), "Toggle fullscreen")
bind("SHIFT + F", hl.dsp.window.fullscreen({ action = "toggle", mode = "maximized" }), "Toggle maximize")

-- Focus ------------------------------------------------------------------
bind("left",  hl.dsp.focus({ direction = "left" }),  "Focus left")
bind("right", hl.dsp.focus({ direction = "right" }), "Focus right")
bind("up",    hl.dsp.focus({ direction = "up" }),    "Focus up")
bind("down",  hl.dsp.focus({ direction = "down" }),  "Focus down")
bind("TAB",   hl.dsp.window.cycle_next(),            "Focus next window")

-- Move / resize windows --------------------------------------------------
bind("SHIFT + left",  hl.dsp.window.move({ direction = "left" }),  "Move window left")
bind("SHIFT + right", hl.dsp.window.move({ direction = "right" }), "Move window right")
bind("SHIFT + up",    hl.dsp.window.move({ direction = "up" }),    "Move window up")
bind("SHIFT + down",  hl.dsp.window.move({ direction = "down" }),  "Move window down")

bind("CTRL + left",  hl.dsp.window.resize({ x = -20, y = 0, relative = true }), "Shrink window horizontally")
bind("CTRL + right", hl.dsp.window.resize({ x = 20,  y = 0, relative = true }), "Grow window horizontally")
bind("CTRL + up",    hl.dsp.window.resize({ x = 0, y = -20, relative = true }), "Shrink window vertically")
bind("CTRL + down",  hl.dsp.window.resize({ x = 0, y = 20,  relative = true }), "Grow window vertically")

-- Workspaces -------------------------------------------------------------
for i = 1, 10 do
    local key = tostring(i % 10)  -- 10 -> "0"
    bind(key,               hl.dsp.focus({ workspace = i }),       "Switch to workspace " .. i)
    bind("SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), "Move window to workspace " .. i)
end

-- Special workspace (scratchpad)
bind("S",         hl.dsp.workspace.toggle_special("magic"),               "Toggle scratchpad")
bind("SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }),    "Move window to scratchpad")

-- Scroll through workspaces with mainMod + scroll
bind("mouse_down", hl.dsp.focus({ workspace = "e+1" }), "Next workspace")
bind("mouse_up",   hl.dsp.focus({ workspace = "e-1" }), "Previous workspace")
bind("SHIFT + mouse_down", hl.dsp.window.move({ workspace = "e+1" }), "Move window to next workspace")
bind("SHIFT + mouse_up",   hl.dsp.window.move({ workspace = "e-1" }), "Move window to previous workspace")

-- Move/resize windows with mainMod + LMB/RMB dragging
bind("mouse:272", hl.dsp.window.drag(),   "Drag window",   { mouse = true })
bind("mouse:273", hl.dsp.window.resize(), "Resize window", { mouse = true })

-- Notifications / menus --------------------------------------------------
bind("A", hl.dsp.exec_cmd("sleep 0.1; swaync-client -t -sw"), "Toggle notification panel")
bind("SHIFT + N", hl.dsp.exec_cmd("swaync-client -d"),        "Toggle do-not-disturb")
bind("U", hl.dsp.exec_cmd("sh ~/.config/rofi/bin/powermenu"), "Open power menu")

-- Lock screen (same styling as the power menu's lock entry)
local lockScreen = table.concat({
    "swaylock --indicator-radius 160 -c 000000",
    "--ring-color b4befe --ring-ver-color b4befe --key-hl-color 000000",
    "--inside-color b4befe --inside-ver-color b4befe --inside-clear-color a6e3a1",
    "--ring-clear-color a6e3a1 --ring-wrong-color f38ba8 --inside-wrong-color f38ba8",
    "--bs-hl-color f38ba8 --text-caps-lock-color 000000",
}, " ")
bind("L", hl.dsp.exec_cmd(lockScreen), "Lock screen")

-- Screenshots ------------------------------------------------------------
-- `mkdir -p` makes the target robust; if `slurp` is cancelled the command
-- short-circuits, so no empty file is written. `$(date ...)` is expanded by
-- the shell at press time, not at config load.
local screenshotDir = (os.getenv("HOME") or "/home/bhhoang") .. "/Pictures/Screenshots"

local function screenshotCmd(region)
    local shot = region and 'region="$(slurp)" && grim -g "$region" -' or "grim -"
    local name = region and "Capture" or "Screenshot"
    local what = region and "region" or "whole screen"
    return 'mkdir -p "' .. screenshotDir .. '" && ' .. shot
        .. ' | tee "' .. screenshotDir .. "/" .. name .. '-$(date +%F_%T).png"'
        .. ' | wl-copy && notify-send "Screenshot of ' .. what .. ' taken" -t 1000'
end

rawBind("Print",         hl.dsp.exec_cmd(screenshotCmd(true)),  "Screenshot a region")
rawBind("SHIFT + Print", hl.dsp.exec_cmd(screenshotCmd(false)), "Screenshot the whole screen")

-- Audio ------------------------------------------------------------------
rawBind("CTRL + M", hl.dsp.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ toggle"), "Toggle audio mute (pactl)")

-- Laptop multimedia keys (wpctl / brightnessctl / playerctl are installed)
rawBind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), "Volume up",   { locked = true, repeating = true })
rawBind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      "Volume down", { locked = true, repeating = true })
rawBind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     "Mute",        { locked = true, repeating = true })
rawBind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   "Mic mute",    { locked = true, repeating = true })
rawBind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  "Brightness up",   { locked = true, repeating = true })
rawBind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  "Brightness down", { locked = true, repeating = true })
rawBind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       "Next track",       { locked = true })
rawBind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), "Play/pause",       { locked = true })
rawBind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), "Play/pause",       { locked = true })
rawBind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   "Previous track",   { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- Ignore maximize requests from all apps (old: windowrulev2 suppressevent).
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Fix dragging issues with XWayland
hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Keep the hyprland-run launcher out of the way (it is installed here)
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- Floating utility windows
hl.window_rule({ name = "float-pavucontrol", match = { class = "pavucontrol" },      float = true })
hl.window_rule({ name = "float-blueman",     match = { class = "blueman-manager" },   float = true })

-- Browser picture-in-picture stays on top and out of the tiling layout
hl.window_rule({
    name  = "picture-in-picture",
    match = { title = "^(Picture-in-Picture|Picture in picture)$" },
    float = true,
    pin   = true,
})

-- Fix pinentry (GPG/SSH agent) losing focus
hl.window_rule({
    name         = "pinentry-focus",
    match        = { class = "(pinentry-)(.*)" },
    stay_focused = true,
})

-- Frosted-glass blur behind Waybar (style: ~/.config/waybar/style.css)
hl.layer_rule({
    name  = "waybar-blur",
    match = { namespace = "waybar" },
    blur  = true,
})

-- Frosted-glass blur behind rofi (theme: ~/.config/rofi/glass.rasi)
hl.layer_rule({
    name         = "rofi-blur",
    match        = { namespace = "rofi" },
    blur         = true,
    ignore_alpha = 0.5,
})

-- Frosted-glass blur behind swaync notifications and control center
hl.layer_rule({
    name  = "swaync-blur",
    match = { namespace = "swaync-.*" },
    blur  = true,
})

-- Per-device example (find names with `hyprctl devices`):
-- hl.device({ name = "my-mouse", sensitivity = -0.5 })
