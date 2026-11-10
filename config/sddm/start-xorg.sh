#!/bin/bash
set -e

external_card=""
internal_card=""

for status in /sys/class/drm/card*-*/status; do
    [ -r "$status" ] || continue
    [ "$(cat "$status")" = connected ] || continue
    connector=${status#/sys/class/drm/}
    connector=${connector%/status}
    card=${connector%%-*}
    output=${connector#*-}
    case "$output" in
        eDP*|LVDS*|DSI*)
            [ -z "$internal_card" ] && internal_card="$card"
            ;;
        *)
            [ -z "$external_card" ] && external_card="$card"
            ;;
    esac
done

busid_for() {
    local pci
    pci=$(basename "$(readlink -f "/sys/class/drm/$1/device")")
    IFS=':.' read -r _ bus dev fn <<< "$pci"
    printf 'PCI:%d:%d:%d' "$((16#$bus))" "$((16#$dev))" "$((16#$fn))"
}

xdriver_for() {
    local driver
    driver=$(basename "$(readlink -f "/sys/class/drm/$1/device/driver")")
    if [ "$driver" = nvidia ] && [ -e /usr/lib/xorg/modules/drivers/nvidia_drv.so ]; then
        echo nvidia
    else
        echo modesetting
    fi
}

mkdir -p /run/sddm
single_cfg=/run/sddm/xorg-single.conf
dual_cfg=/run/sddm/xorg-dual.conf

card=${external_card:-$internal_card}
[ -z "$card" ] && card=card0
busid=$(busid_for "$card")
xdriver=$(xdriver_for "$card")

cat > "$single_cfg" <<XEOF
Section "Device"
    Identifier "SDDM GPU"
    Driver "$xdriver"
    BusID "$busid"
    Option "AllowEmptyInitialConfiguration" "true"
EndSection

Section "Screen"
    Identifier "SDDM Screen"
    Device "SDDM GPU"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
    EndSubSection
EndSection

Section "ServerLayout"
    Identifier "SDDM Layout"
    Screen 0 "SDDM Screen"
EndSection
XEOF

cfg=$single_cfg

# With the flag present, start the X server with the internal GPU as the
# primary screen and the NVIDIA GPU as an inactive Reverse PRIME sink. Xsetup
# then mirrors the external output onto the internal panel.
if [ -e /etc/sddm/mirror-both ] \
   && [ -n "$internal_card" ] && [ -n "$external_card" ] \
   && [ "$internal_card" != "$external_card" ] \
   && [ "$(xdriver_for "$external_card")" = nvidia ]; then
    internal_busid=$(busid_for "$internal_card")
    external_busid=$(busid_for "$external_card")

    cat > "$dual_cfg" <<XEOF
Section "Device"
    Identifier "Internal GPU"
    Driver "modesetting"
    BusID "$internal_busid"
    Option "AllowEmptyInitialConfiguration" "true"
EndSection

Section "Device"
    Identifier "External GPU"
    Driver "nvidia"
    BusID "$external_busid"
    Option "AllowEmptyInitialConfiguration" "true"
EndSection

Section "Screen"
    Identifier "Internal Screen"
    Device "Internal GPU"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
    EndSubSection
EndSection

Section "ServerLayout"
    Identifier "SDDM Layout"
    Screen 0 "Internal Screen"
    Inactive "External GPU"
    Option "AllowNVIDIAGPUScreens"
EndSection
XEOF
    cfg=$dual_cfg
fi

exec /usr/bin/X -config "$cfg" "$@"
