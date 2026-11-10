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

`Duplicate` uses Hyprland's native mirror when both outputs are on the same
DRM card. When the panel and the external output are on different GPUs it
falls back to `wl-mirror`, which copies the composed image the same way
Windows' display duplication does. The mirrored output is view-only: keyboard
and pointer input stay on the laptop.

While duplicating, both outputs run at scale 1. The panel normally uses 1.5x,
so copying a 1280x720 logical image to a 1x 1920x1080 output would blur the
text. The UI is therefore smaller on the laptop while this profile is active.

A firmware MUX / Discrete Graphics / PEG setting that moves the panel onto the
dGPU also makes the native mirror work, with no `wl-mirror` involved.

The Hyprland monitor setup is auto-detected, and the NVIDIA environment lines
in `hyprland.lua` are commented out, so it is not tied to this GPU.
