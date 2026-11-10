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
- `big_icon_size 144`, `small_icon_size 32`
- `os_arch.png` — 256×256 canvas with a padded white Arch glyph; the visible
  glyph is 72px inside the 144px icon slot
- `selection_big_144.png` / `selection_small_64.png` — clean rounded glass
  capsules, no clipped outer halo
- Built-in rEFInd font; dynamic label/countdown; `hideui hints,arrows`
- The full icon set is under `theme/icons/`; tool icons are recolored white

The `refind_x64.efi` binary is not tracked. Install it with `refind-install` or
copy it from the `refind` package.
