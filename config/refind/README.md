# rEFInd theme

Install:

- `refind.conf` → `/boot/EFI/refind/refind.conf` (primary)
- `refind.conf` → `/boot/EFI/BOOT/refind.conf` (fallback)
- `theme/` → `/boot/EFI/refind/theme/`
- `../refind_linux.conf` → `/boot/refind_linux.conf`

Theme:

- `bg-adaptive.png` — 2560×1440 blurred wallpaper used as a full-screen banner
  (`banner_scale fillscreen`), so it scales to the display instead of baking a
  fixed panel
- `big_icon_size 144`, `small_icon_size 64`
- OS icons — 256×256 canvases with ~120px of visible artwork (≈67px inside
  the 144px slot). `os_arch.png` keeps the white Arch glyph, and every other
  `os_*`/`boot_*` icon is trimmed and padded to the same ratio so they do not
  fill the selection capsule
- `selection_big_144.png` / `selection_small_64.png` — clean rounded glass
  capsules, no clipped outer halo
- Tool icons are padded: 32px glyphs inside 64px slots, so they do not fill
  the selection capsules
- `showtools reboot` — removes the optional EFI shell/hidden-tags tools and
  keeps the core tools plus reboot
- `hideui hints,arrows,badges` — hides hints, scroll arrows, and the volume
  drive badge
- Built-in rEFInd font; dynamic label/countdown

## Portability

- The theme assets (`bg-adaptive.png`, selection capsules, icon set) are
  portable and have no GPU dependency.
- `big_icon_size` / `small_icon_size` are fixed pixel sizes; rEFInd has no
  auto or percentage icon sizing. Adjust them for the target resolution; the
  background itself scales.
- Update the root UUID in `refind_linux.conf` and the manual entry `options`,
  and the ESP label in `dont_scan_volumes`, for another machine.
- The firmware boot menu output is controlled by the firmware/BIOS, not by
  rEFInd or this theme.

The full icon set is under `theme/icons/`. The `refind_x64.efi` binary is not
tracked. Install it with `refind-install` or copy it from the `refind` package.
