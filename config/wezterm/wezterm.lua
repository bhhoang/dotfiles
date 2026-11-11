-- WezTerm: glassmorphism terminal matching the Waybar/rofi palette.
local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Keep XWayland: fcitx5 input works reliably there for Vietnamese typing.
config.enable_wayland = false

-- Font -----------------------------------------------------------------------
config.font = wezterm.font_with_fallback({
    { family = "NotoSansM Nerd Font Mono", weight = "Regular" },
    { family = "Noto Sans Mono" },
    { family = "Noto Sans Mono CJK JP" },
    { family = "Noto Color Emoji" },
})
config.font_size = 11.0
config.line_height = 1.15
config.cell_width = 1.0

-- Palette: Catppuccin Mocha, the same accents as Waybar and rofi ------------
local c = {
    base     = "#11111b",
    mantle   = "#181825",
    surface0 = "#313244",
    surface1 = "#45475a",
    surface2 = "#585b70",
    text     = "#cdd6f4",
    subtext0 = "#a6adc8",
    lavender = "#b4befe",
    sapphire = "#89dceb",
    red      = "#f38ba8",
    green    = "#a6e3a1",
    yellow   = "#f9e2af",
    blue     = "#89b4fa",
    pink     = "#f5c2e7",
    teal     = "#94e2d5",
}

config.colors = {
    background      = c.base,
    foreground      = c.text,
    cursor_bg       = c.lavender,
    cursor_fg       = c.base,
    cursor_border   = c.lavender,
    selection_bg    = c.surface1,
    selection_fg    = c.text,
    scrollbar_thumb = c.surface2,
    split           = c.sapphire,
    compose_cursor  = c.pink,
    ansi = {
        c.surface1, c.red, c.green, c.yellow,
        c.blue, c.pink, c.teal, c.subtext0,
    },
    brights = {
        c.surface2, c.red, c.green, c.yellow,
        c.blue, c.pink, c.teal, c.text,
    },
    tab_bar = {
        background = c.base,
        active_tab = { bg_color = c.lavender, fg_color = c.base },
        inactive_tab = { bg_color = c.mantle, fg_color = c.subtext0 },
        inactive_tab_hover = { bg_color = c.surface0, fg_color = c.text },
        new_tab = { bg_color = c.base, fg_color = c.subtext0 },
        new_tab_hover = { bg_color = c.surface0, fg_color = c.text },
    },
}

-- Glass window ---------------------------------------------------------------
config.window_background_opacity = 0.86
config.text_background_opacity = 1.0
config.window_decorations = "NONE"
config.window_padding = { left = 14, right = 14, top = 12, bottom = 12 }
config.window_frame = {
    font = wezterm.font({ family = "NotoSansM Nerd Font Mono", weight = "Bold" }),
    font_size = 10.0,
    active_titlebar_bg = c.base,
    inactive_titlebar_bg = c.base,
}

-- Tabs / cursor / behaviour --------------------------------------------------
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_max_width = 32
config.enable_scroll_bar = false
config.scrollback_lines = 20000
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 600
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.7 }
config.audible_bell = "Disabled"
config.adjust_window_size_when_changing_font_size = false

return config
