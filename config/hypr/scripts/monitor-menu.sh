#!/usr/bin/env bash
# Rofi picker for the Hyprland monitor profiles.
#
# The available profiles, the current profile and the application logic all
# come from the running Lua config, so no output names are hardcoded here.

set -euo pipefail
export LC_ALL=C.UTF-8

# hyprctl needs the instance signature. Hyprland exports it to spawned
# processes, but derive it when the script is launched from elsewhere.
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    signature="$(find "$runtime/hypr" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | head -n1)"
    if [[ -z "$signature" ]]; then
        echo "monitor-menu: no running Hyprland instance found" >&2
        exit 1
    fi
    export HYPRLAND_INSTANCE_SIGNATURE="$signature"
fi

# Profiles that can currently be applied (missing outputs are filtered out).
mapfile -t profiles < <(hyprctl repl 'return table.concat(hyprMonitorProfilesAvailable(), "\n")' 2>/dev/null)
if (( ${#profiles[@]} == 0 )); then
    echo "monitor-menu: could not read monitor profiles from Hyprland" >&2
    exit 1
fi

# Icon + label for each profile. Names are capitalized by the Lua config.
declare -A label=(
    ["Extend"]=$'\uF108  Extend'
    ["External only"]=$'\uF26C  External only'
    ["Duplicate"]=$'\uF24D  Duplicate'
    ["Laptop only"]=$'\uF109  Laptop only'
)

menu=()
for profile in "${profiles[@]}"; do
    menu+=("${label[$profile]:-$profile}")
done

current="$(hyprctl repl 'return hyprDetectMonitorProfile()' 2>/dev/null | tr -d '\r')"

rofi_args=(-dmenu -i -no-custom -lines "${#menu[@]}" -theme "$HOME/.config/rofi/config/monitor.rasi")
if [[ -n "$current" && "$current" != "nil" ]]; then
    rofi_args+=(-select "$current")
fi

choice="$(printf '%s\n' "${menu[@]}" | rofi "${rofi_args[@]}")" || exit 0
[[ -n "$choice" ]] || exit 0

# Rows are "<icon>  <profile>"; strip the icon before applying.
profile="${choice#*  }"
hyprctl eval "hyprSetMonitorProfile([[${profile}]])" >/dev/null
