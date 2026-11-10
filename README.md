# dotfiles
Dotfiles for my arch config

## rEFInd
- `config/refind/refind.conf` → `/boot/EFI/refind/refind.conf` and `/boot/EFI/BOOT/refind.conf`
- `config/refind/theme/` → `/boot/EFI/refind/theme/`
- `refind_linux.conf` → `/boot/refind_linux.conf`

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
present. The generated Xorg config is `/run/sddm/xorg.conf`.

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

The profiles assume one internal panel plus one external output. On a desktop
with only external monitors, `Extend` leaves the auto layout alone and the
panel-specific profiles are hidden.

The Hyprland monitor setup is auto-detected, and the NVIDIA environment lines
in `hyprland.lua` are commented out, so it is not tied to this GPU.
