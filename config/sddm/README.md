# SDDM external greeter

Install:

- `start-xorg.sh` → `/etc/sddm/start-xorg.sh` (chmod 755)
- `10-xsetup.conf` → `/etc/sddm.conf.d/10-xsetup.conf`
- `Xsetup` → `/etc/sddm/scripts/Xsetup` (chmod 755)

## How it works

`start-xorg.sh` scans `/sys/class/drm/card*-*/status`, finds the DRM card with
a connected external output (HDMI/DP, not eDP/LVDS/DSI), and chooses:

- NVIDIA with the Xorg `nvidia` driver installed → `Driver "nvidia"`
- NVIDIA without the Xorg driver, Intel/AMD/other → `Driver "modesetting"`

If no external display is connected, it uses the internal panel. The generated
Xorg configuration is written to `/run/sddm/xorg.conf` and passed to Xorg with
`-config`.

`Xsetup` then lays out the displays:

- The first connected external output becomes primary
- Additional external outputs on the same GPU are mirrored to it
- The internal panel is turned off when an external output exists
- If no external output is connected, the internal panel is left on

Outputs on a different GPU are outside the SDDM Xorg screen; the launcher
starts the greeter on the card that owns the first external output.

```ini
[X11]
DisplayCommand=/etc/sddm/scripts/Xsetup
ServerPath=/etc/sddm/start-xorg.sh
ServerArguments=-nolisten tcp
```

This is GPU-agnostic: the same files work on an NVIDIA laptop, an Intel/AMD
laptop, or a machine without a discrete GPU. It does not modify the global
Xorg configuration, so the Hyprland/Xwayland session is unaffected.

## Recovery

If the greeter is black or fails:

1. Switch to a TTY with `Ctrl+Alt+F2` and log in.
2. Remove the new files:
   ```sh
   sudo rm /etc/sddm.conf.d/10-xsetup.conf
   sudo rm /etc/sddm/start-xorg.sh
   sudo rm /etc/sddm/scripts/Xsetup
   ```
3. Restart SDDM:
   ```sh
   sudo systemctl restart sddm
   ```

## Bootloader note

The firmware boot menu (rEFInd) may still appear on the internal panel. rEFInd
cannot choose the output; the firmware initializes the boot display. Check the
BIOS for Primary Display / Discrete Graphics / PEG settings to move the
firmware boot display to the external HDMI output.
