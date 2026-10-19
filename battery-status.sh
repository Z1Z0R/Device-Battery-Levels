#!/bin/sh

normalize() {
  printf '%s' "$1" | tr -cd '[:alnum:]' | tr '[:lower:]' '[:upper:]'
}

matches_device_props() {
  props=$1
  event_serial=$(printf '%s\n' "$props" | sed -n 's/^ID_SERIAL_SHORT=//p' | head -n 1)
  event_model=$(printf '%s\n' "$props" | sed -n 's/^ID_MODEL=//p' | head -n 1)
  event_vendor=$(printf '%s\n' "$props" | sed -n 's/^ID_VENDOR=//p' | head -n 1)

  if [ -n "$battery_serial" ] && [ -n "$event_serial" ]; then
    [ "$battery_serial" = "$(normalize "$event_serial")" ]
  elif [ -n "$battery_model" ] && [ "$battery_model" = "$(normalize "$event_model")" ]; then
    [ -z "$battery_vendor" ] || [ -z "$event_vendor" ] || [ "$battery_vendor" = "$(normalize "$event_vendor")" ]
  else
    return 1
  fi
}

mouse_name=
mouse_capacity=-1
mouse_status=Unknown
mouse_online=0
keyboard_name=
keyboard_capacity=-1
keyboard_status=Unknown
keyboard_online=0
headphones_name=
headphones_capacity=-1
headphones_status=Unknown
headphones_online=0
laptop_name=
laptop_capacity=-1
laptop_status=Unknown

for supply in /sys/class/power_supply/*; do
  [ -r "$supply/uevent" ] || continue
  supply_data=$(cat "$supply/uevent")
  supply_type=$(printf '%s\n' "$supply_data" | sed -n 's/^POWER_SUPPLY_TYPE=//p' | head -n 1)
  [ "$supply_type" = Battery ] || continue

  name=$(printf '%s\n' "$supply_data" | sed -n 's/^POWER_SUPPLY_MODEL_NAME=//p' | head -n 1)
  manufacturer=$(printf '%s\n' "$supply_data" | sed -n 's/^POWER_SUPPLY_MANUFACTURER=//p' | head -n 1)
  serial=$(printf '%s\n' "$supply_data" | sed -n 's/^POWER_SUPPLY_SERIAL_NUMBER=//p' | head -n 1)
  if [ -r "$supply/device/uevent" ]; then
    device_data=$(cat "$supply/device/uevent")
    [ -n "$serial" ] || serial=$(printf '%s\n' "$device_data" | sed -n 's/^HID_UNIQ=//p' | head -n 1)
    [ -n "$name" ] || name=$(printf '%s\n' "$device_data" | sed -n 's/^HID_NAME=//p' | head -n 1)
  fi

  battery_serial=$(normalize "$serial")
  battery_model=$(normalize "$name")
  battery_vendor=$(normalize "$manufacturer")
  has_mouse=0
  has_keyboard=0
  has_headphones=0

  case "$battery_model" in
    *HEADSET*|*HEADPHONE*|*EARPHONE*|*EARBUD*|*AIRPOD*|*BUDS*) has_headphones=1 ;;
  esac

  for event in /sys/class/input/event*; do
    [ -e "$event" ] || continue
    props=$(udevadm info -q property -p "$event" 2>/dev/null) || continue
    matches_device_props "$props" || continue
    printf '%s\n' "$props" | grep -qx 'ID_INPUT_MOUSE=1' && has_mouse=1
    printf '%s\n' "$props" | grep -qx 'ID_INPUT_KEYBOARD=1' && has_keyboard=1
  done

  for card in /sys/class/sound/card*; do
    [ -e "$card" ] || continue
    props=$(udevadm info -q property -p "$card" 2>/dev/null) || continue
    if matches_device_props "$props"; then has_headphones=1; fi
  done

  kind=
  if [ "$has_headphones" = 1 ]; then kind=headphones
  elif [ "$has_mouse" = 1 ]; then kind=mouse
  elif [ "$has_keyboard" = 1 ]; then kind=keyboard
  else
    supply_basename=$(basename "$supply")
    scope=$(printf '%s\n' "$supply_data" | sed -n 's/^POWER_SUPPLY_SCOPE=//p' | head -n 1)
    case "$scope:$supply_basename" in
      System:*|*:BAT[0-9]*|*:battery|*:macsmc-battery) kind=laptop ;;
    esac
  fi
  [ -n "$kind" ] || continue

  capacity=$(printf '%s\n' "$supply_data" | sed -n 's/^POWER_SUPPLY_CAPACITY=//p' | head -n 1)
  status=$(printf '%s\n' "$supply_data" | sed -n 's/^POWER_SUPPLY_STATUS=//p' | head -n 1)
  online=$(printf '%s\n' "$supply_data" | sed -n 's/^POWER_SUPPLY_ONLINE=//p' | head -n 1)
  [ -n "$name" ] || name=$(basename "$supply")

  if [ "$kind" = mouse ]; then
    if [ "$mouse_capacity" = -1 ] || { [ "$online" = 1 ] && [ "$mouse_online" != 1 ]; } || { [ "$online" = "$mouse_online" ] && [ "$status" = Charging ] && [ "$mouse_status" != Charging ]; }; then
      mouse_name=$name
      mouse_capacity=${capacity:--1}
      mouse_status=${status:-Unknown}
      mouse_online=${online:-0}
    fi
  elif [ "$kind" = keyboard ]; then
    if [ "$keyboard_capacity" = -1 ] || { [ "$online" = 1 ] && [ "$keyboard_online" != 1 ]; } || { [ "$online" = "$keyboard_online" ] && [ "$status" = Charging ] && [ "$keyboard_status" != Charging ]; }; then
      keyboard_name=$name
      keyboard_capacity=${capacity:--1}
      keyboard_status=${status:-Unknown}
      keyboard_online=${online:-0}
    fi
  elif [ "$kind" = headphones ]; then
    if [ "$headphones_capacity" = -1 ] || { [ "$online" = 1 ] && [ "$headphones_online" != 1 ]; } || { [ "$online" = "$headphones_online" ] && [ "$status" = Charging ] && [ "$headphones_status" != Charging ]; }; then
      headphones_name=$name
      headphones_capacity=${capacity:--1}
      headphones_status=${status:-Unknown}
      headphones_online=${online:-0}
    fi
  else
    laptop_name=$name
    laptop_capacity=${capacity:--1}
    laptop_status=${status:-Unknown}
  fi
done

printf 'MOUSE_NAME=%s\nMOUSE_CAPACITY=%s\nMOUSE_STATUS=%s\nKEYBOARD_NAME=%s\nKEYBOARD_CAPACITY=%s\nKEYBOARD_STATUS=%s\nHEADPHONES_NAME=%s\nHEADPHONES_CAPACITY=%s\nHEADPHONES_STATUS=%s\nLAPTOP_NAME=%s\nLAPTOP_CAPACITY=%s\nLAPTOP_STATUS=%s\n' \
  "$mouse_name" "$mouse_capacity" "$mouse_status" "$keyboard_name" "$keyboard_capacity" "$keyboard_status" "$headphones_name" "$headphones_capacity" "$headphones_status" "$laptop_name" "$laptop_capacity" "$laptop_status"
