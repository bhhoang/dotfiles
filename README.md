# dotfiles
Dotfiles for my arch config

## rEFInd
- `config/refind/refind.conf` → `/boot/EFI/refind/refind.conf` and `/boot/EFI/BOOT/refind.conf`
- `config/refind/theme/` → `/boot/EFI/refind/theme/`
- `refind_linux.conf` → `/boot/refind_linux.conf`

## WezTerm
- `config/wezterm/wezterm.lua` → `~/.config/wezterm/wezterm.lua`

Noto Sans Mono with the Catppuccin Mocha palette, a translucent background
(blurred by Hyprland), a borderless window, and tabs styled to match Waybar
and rofi. XWayland is kept enabled for reliable fcitx5 input.

## OpenCode
- `config/opencode/cli.json` → `~/.config/opencode/cli.json`

The TUI uses the `system` theme, so it inherits WezTerm’s Catppuccin palette
and the glass background. `mode: dark` keeps it from switching to a light
palette.

## SDDM / Xorg
- `config/sddm/start-xorg.sh` → `/etc/sddm/start-xorg.sh` (chmod +x)
- `config/sddm/10-xsetup.conf` → `/etc/sddm.conf.d/10-xsetup.conf`
- `config/sddm/Xsetup` → `/etc/sddm/scripts/Xsetup` (chmod +x)

`start-xorg.sh` detects the DRM card that owns the connected external output:

- NVIDIA with the Xorg driver installed → `Driver "nvidia"`
- NVIDIA without the Xorg driver, Intel/AMD/other → `Driver "modesetting"`

It falls back to the internal panel when no external display is connected.
`Xsetup` makes the first external output primary, mirrors additional external
outputs on the same GPU, and turns off the internal panel when an external is
present. The generated Xorg config is `/run/sddm/xorg-single.conf`.

With `/etc/sddm/mirror-both`, and when the panel and the external output are on
different GPUs, `start-xorg.sh` writes `/run/sddm/xorg-dual.conf` instead: the
internal GPU is the primary `modesetting` screen and the NVIDIA GPU is an
inactive Reverse PRIME sink. `Xsetup` attaches it and mirrors the external
output onto the internal panel, so the greeter appears on both screens.
Remove the flag to return to the external-only greeter.

The firmware boot menu may still appear on the internal panel; use the BIOS
Primary Display / Discrete Graphics / PEG setting to move it.

Machine-specific values:

- wallpaper path in `config/hypr/hyprpaper.conf`
- root UUID in `refind_linux.conf` and the manual rEFInd entry
- ESP label in `config/refind/refind.conf`
- rEFInd icon sizes are fixed pixels; adjust them for other resolutions

## Hyprland monitor profiles

`SUPER + SHIFT + M` cycles `Extend`, `External only`, `Duplicate`, and
`Laptop only`. Profiles whose outputs are not connected are skipped.

`Duplicate` uses Hyprland's native compositor mirror: the external output is
routed to the laptop panel's workspace (`mirrorOf`), so both screens show the
same workspace and cursor. Both outputs use the lower of their two scales,
which keeps the lower-DPI screen at 1:1 and avoids upscaling blur. The mirror
works across GPUs; no firmware MUX is involved.

`Extend` caps a 1080p internal panel at 1.25 instead of Hyprland's PPI-based
auto value (1.5 here); `Laptop only` uses 1.0. Denser panels keep the auto
scale.

The profiles assume one internal panel plus one external output. On a desktop
with only external monitors, `Extend` leaves the auto layout alone and the
panel-specific profiles are hidden.

The Hyprland monitor setup is auto-detected, and the NVIDIA environment lines
in `hyprland.lua` are commented out, so it is not tied to this GPU.
