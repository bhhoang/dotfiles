# SDDM external display

Install:

- `xorg-nvidia.conf` → `/etc/sddm/xorg-nvidia.conf`
- `10-xsetup.conf` → `/etc/sddm.conf.d/10-xsetup.conf`
- `Xsetup` → `/etc/sddm/scripts/Xsetup` (chmod 755)

The external HDMI-A-4 output is wired to the NVIDIA GPU. The Xorg
configuration is applied only to SDDM via:

```ini
[X11]
DisplayCommand=/etc/sddm/scripts/Xsetup
ServerArguments=-nolisten tcp -config /etc/sddm/xorg-nvidia.conf
```

`Xsetup` makes the connected external output primary before the greeter
starts. The global Xorg configuration is deliberately left untouched so the
Hyprland/Xwayland session is not affected.

## Recovery

If the greeter is black or fails:

1. Switch to a TTY with `Ctrl+Alt+F2` and log in.
2. Remove the new files:
   ```sh
   sudo rm /etc/sddm/xorg-nvidia.conf
   sudo rm /etc/sddm.conf.d/10-xsetup.conf
   sudo rm /etc/sddm/scripts/Xsetup
   ```
3. Restart SDDM:
   ```sh
   sudo systemctl restart sddm
   ```

## Bootloader note

The firmware boot menu (rEFInd) may still appear on the Intel eDP instead of
the external HDMI. rEFInd cannot choose the output; the firmware initializes
the boot display. Check the BIOS for Primary Display / Discrete Graphics /
PEG settings to move the firmware boot display to the NVIDIA HDMI output.
