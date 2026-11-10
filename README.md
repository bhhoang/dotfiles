# dotfiles
Dotfiles for my arch config

## rEFInd
- `config/refind/refind.conf` → `/boot/EFI/refind/refind.conf` and `/boot/EFI/BOOT/refind.conf`
- `config/refind/theme/` → `/boot/EFI/refind/theme/`
- `refind_linux.conf` → `/boot/refind_linux.conf`

## SDDM / Xorg
- `config/sddm/xorg-nvidia.conf` → `/etc/sddm/xorg-nvidia.conf`
- `config/sddm/10-xsetup.conf` → `/etc/sddm.conf.d/10-xsetup.conf`
- `config/sddm/Xsetup` → `/etc/sddm/scripts/Xsetup` (chmod +x)

HDMI-A-4 is wired to the NVIDIA GPU. SDDM’s X11 greeter is scoped to the NVIDIA Xorg configuration so the login screen appears on the external display. The firmware boot menu may still appear on the Intel eDP; use the BIOS Primary Display / Discrete Graphics / PEG setting to move the boot menu.
