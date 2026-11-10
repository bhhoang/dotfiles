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

Hyprland cannot mirror across GPUs, so `Duplicate` is only offered when the
internal panel and the external output are on the same DRM card. Laptops that
wire the panel to the iGPU and HDMI to the dGPU need a firmware MUX /
Discrete Graphics / PEG setting to make a real duplicate possible; otherwise
use `Extend` or `External only`, or a software mirror such as `wl-mirror`.

The Hyprland monitor setup is auto-detected, and the NVIDIA environment lines
in `hyprland.lua` are commented out, so it is not tied to this GPU.
