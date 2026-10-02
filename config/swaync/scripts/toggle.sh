#!/bin/sh
# swaync 快捷开关：toggle.sh <wifi|bluetooth> <status|set>
# status 输出 true/false；set 按 swaync 传入的 $SWAYNC_TOGGLE_STATE 开关
case "$1:$2" in
  wifi:status)      [ "$(nmcli radio wifi)" = enabled ] && echo true || echo false ;;
  wifi:set)         [ "$SWAYNC_TOGGLE_STATE" = true ] && nmcli radio wifi on || nmcli radio wifi off ;;
  bluetooth:status) bluetoothctl show | grep -q 'Powered: yes' && echo true || echo false ;;
  bluetooth:set)    [ "$SWAYNC_TOGGLE_STATE" = true ] && bluetoothctl power on || bluetoothctl power off ;;
esac
