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

It writes `/run/sddm/xorg-single.conf` and passes it to Xorg with `-config`.

### Two-screen greeter

With the flag `/etc/sddm/mirror-both`, and when the internal panel and the
external output are on different cards, it writes `/run/sddm/xorg-dual.conf`
instead: the internal GPU becomes the primary `modesetting` screen and the
NVIDIA GPU is an inactive Reverse PRIME sink.

`Xsetup` then:

- attaches the NVIDIA provider with `xrandr --setprovideroutputsource`
- enables the internal panel as primary
- mirrors the external output onto it with `xrandr --same-as`
- falls back to the internal panel if the mirror cannot be created

Without the flag, or if the mirror fails, it uses the single-GPU layout:

- The first connected external output becomes primary
- Additional external outputs on the same GPU are mirrored to it
- The internal panel is turned off when an external output exists
- If no external output is connected, the internal panel is left on

```ini
[X11]
DisplayCommand=/etc/sddm/scripts/Xsetup
ServerPath=/etc/sddm/start-xorg.sh
ServerArguments=-nolisten tcp
```

The default path is GPU-agnostic: the same files work on an NVIDIA laptop, an
Intel/AMD laptop, or a machine without a discrete GPU. It does not modify the
global Xorg configuration, so the Hyprland/Xwayland session is unaffected. The
two-screen mode requires the NVIDIA Reverse PRIME sink and is skipped
otherwise.

## Recovery

If the two-screen greeter is black or only appears on one screen:

1. Switch to a TTY with `Ctrl+Alt+F2` and log in.
2. Remove the flag and restart SDDM:
   ```sh
   sudo rm /etc/sddm/mirror-both
   sudo systemctl restart sddm
   ```
   This returns to the external-only greeter.

If SDDM still fails, remove the new files and restart it:

```sh
sudo rm /etc/sddm.conf.d/10-xsetup.conf
sudo rm /etc/sddm/start-xorg.sh
sudo rm /etc/sddm/scripts/Xsetup
sudo systemctl restart sddm
```

## Bootloader note

The firmware boot menu (rEFInd) may still appear on the internal panel. rEFInd
cannot choose the output; the firmware initializes the boot display. Check the
BIOS for Primary Display / Discrete Graphics / PEG settings to move the
firmware boot display to the external HDMI output.
