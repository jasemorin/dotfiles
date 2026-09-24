#!/usr/bin/env bash
# 下次启动进 macOS（只这一次），然后立即重启；在 macOS 里关机/重启后默认回到 Linux
# 用 pkexec 弹密码框（niri 快捷键 caps+shift+esc 调用，密码框同时起到确认作用）
set -euo pipefail
pkexec asahi-bless --set-boot-macos --next -y
systemctl reboot
