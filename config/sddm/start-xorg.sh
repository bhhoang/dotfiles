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

card=${external_card:-$internal_card}
[ -z "$card" ] && card=card0

driver=$(basename "$(readlink -f "/sys/class/drm/$card/device/driver")")
pci=$(basename "$(readlink -f "/sys/class/drm/$card/device")")
IFS=':.' read -r _ bus dev fn <<< "$pci"
busid=$(printf 'PCI:%d:%d:%d' "$((16#$bus))" "$((16#$dev))" "$((16#$fn))")

case "$driver" in
    nvidia)
        if [ -e /usr/lib/xorg/modules/drivers/nvidia_drv.so ]; then
            xdriver=nvidia
        else
            xdriver=modesetting
        fi
        ;;
    *)
        xdriver=modesetting
        ;;
esac

mkdir -p /run/sddm
cfg=/run/sddm/xorg.conf
cat > "$cfg" <<XEOF
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

exec /usr/bin/X -config "$cfg" "$@"
