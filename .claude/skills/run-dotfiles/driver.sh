#!/usr/bin/env bash
# 驱动正在运行的 niri 桌面：校验配置、重启顶栏、截图。给 agent 用（它的 shell 不在 niri 里，没有 NIRI_SOCKET）
# 用法见同目录 SKILL.md；./driver.sh help
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
OUT="${OUT:-/tmp/dotfiles-driver}"   # 截图和日志
mkdir -p "$OUT"

# agent 的 shell 不是 niri 启动的：自己找 socket 和 Wayland display
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
if [[ -z "${NIRI_SOCKET:-}" ]]; then
  NIRI_SOCKET=$(ls -t "$XDG_RUNTIME_DIR"/niri.*.sock 2>/dev/null | head -1 || true)
  export NIRI_SOCKET
fi
# WAYLAND_DISPLAY 为空或是过期的值（socket 不存在）都要重新推断，否则 Qt 退回 xcb，栏画不出来但日志照样 Loaded
if [[ -n "$NIRI_SOCKET" && ! -S "$XDG_RUNTIME_DIR/${WAYLAND_DISPLAY:-none}" ]]; then
  # niri.wayland-1.12345.sock -> wayland-1
  WAYLAND_DISPLAY=$(basename "$NIRI_SOCKET" | cut -d. -f2)
  export WAYLAND_DISPLAY
fi
export QT_QPA_PLATFORM=wayland

need_niri() {
  [[ -n "$NIRI_SOCKET" && -S "$NIRI_SOCKET" ]] || { echo "没有运行中的 niri 会话（找不到 $XDG_RUNTIME_DIR/niri.*.sock）" >&2; exit 1; }
}

# quickshell 可执行文件：系统装的 qs，或 QS_ROOT 下解压的 RPM（没 sudo 时用，见 SKILL.md）
# 环境变量要在这里（顶层）设：在 $(qs_cmd) 子 shell 里 export 传不回来
if [[ -n "${QS_ROOT:-}" ]]; then
  export LD_LIBRARY_PATH="$QS_ROOT/usr/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  export QML_IMPORT_PATH="$QS_ROOT/usr/lib64/qt6/qml" QML2_IMPORT_PATH="$QS_ROOT/usr/lib64/qt6/qml"
fi
qs_cmd() {
  if [[ -n "${QS_ROOT:-}" ]]; then
    echo "$QS_ROOT/usr/bin/quickshell"
  elif command -v qs >/dev/null; then
    echo qs
  fi
}

cmd_check() {
  local fail=0
  echo "== niri"
  niri validate -c "$DOTFILES/config/niri/config.kdl" 2>&1 | grep -E "valid|rror" || fail=1
  echo "== shell 脚本（bash -n + shellcheck）"
  for f in "$DOTFILES"/install.sh "$DOTFILES"/restore.sh "$DOTFILES"/scripts/*.sh "$DOTFILES"/.claude/skills/run-dotfiles/driver.sh; do
    bash -n "$f" || fail=1
  done
  if command -v shellcheck >/dev/null; then
    shellcheck -S warning "$DOTFILES"/install.sh "$DOTFILES"/restore.sh "$DOTFILES"/scripts/*.sh && echo "shellcheck 通过" || fail=1
  fi
  echo "== 链接（install.sh --dry-run，应全是「已就位」）"
  "$DOTFILES/install.sh" --dry-run | grep -v -E "已就位|^$|^完成" || echo "全部已就位"
  echo "== dconf.ini 里不能有被系统锁定的键"
  if grep -q '^\[org/gnome/login-screen\]' "$DOTFILES/system/dconf.ini"; then echo "有 login-screen 段：dconf load 会失败"; fail=1; else echo "OK"; fi
  echo "== quickshell 配置能否加载"
  local qs; qs=$(qs_cmd)
  if [[ -z "$qs" ]]; then
    echo "跳过：没装 quickshell，也没设 QS_ROOT"
  elif [[ -n "$NIRI_SOCKET" ]]; then
    # 真的启动一个实例（会短暂多出一条栏），看日志是否到 Configuration Loaded 且没有 ERROR
    local log="$OUT/qs-check.log"
    timeout 6 "$qs" -p "$DOTFILES/config/quickshell" >"$log" 2>&1 || true
    if grep -q "Configuration Loaded" "$log" && ! grep -q -E "ERROR|Failed to create wl_display|Could not create attached" "$log"; then echo "加载成功"; else cat "$log"; fail=1; fi
  fi
  return $fail
}

cmd_bar() {
  need_niri
  pkill -x waybar 2>/dev/null || true
  pkill -x quickshell 2>/dev/null || true
  pkill -x qs 2>/dev/null || true
  sleep 0.5
  local qs; qs=$(qs_cmd)
  if [[ -n "$qs" ]]; then
    # 让 niri 来启动：成为 niri 的子进程（agent 的 shell 退出后还在），Wayland 环境也是 niri 的
    local envs=()
    [[ -n "${QS_ROOT:-}" ]] && envs=(env "LD_LIBRARY_PATH=$LD_LIBRARY_PATH" "QML_IMPORT_PATH=$QML_IMPORT_PATH" "QML2_IMPORT_PATH=$QML2_IMPORT_PATH")
    niri msg action spawn -- sh -c 'exec "$@" >"'"$OUT/bar.log"'" 2>&1' sh "${envs[@]}" "$qs" -p "$DOTFILES/config/quickshell"
    # 以 niri 里出现 quickshell-bar 图层为准：连不上 Wayland 时日志也会写 Configuration Loaded
    if timeout 10 bash -c "until niri msg layers | grep -q '\"quickshell-bar\"'; do sleep 0.2; done"; then
      echo "quickshell 顶栏已显示，日志 $OUT/bar.log"
    else
      echo "quickshell 顶栏没出现，日志 $OUT/bar.log：" >&2
      grep -E "ERROR|WARN" "$OUT/bar.log" | grep -v "host portal" >&2
      return 1
    fi
  else
    niri msg action spawn -- waybar
    echo "没有 quickshell：已启动 waybar"
  fi
}

# 截图：niri 的截图是异步的，要等文件写完
cmd_ss() {
  need_niri
  local name="${1:-screen}" crop="${2:-}"
  local f="$OUT/$name.png"
  rm -f "$f"
  niri msg action screenshot-screen -p false --path "$f"
  timeout 10 bash -c "until [[ -s '$f' ]] && python3 -c 'from PIL import Image; Image.open(\"$f\").load()' 2>/dev/null; do sleep 0.2; done"
  if [[ "$crop" == top ]]; then
    # 只要顶栏那一条（物理像素，缩放 1.67 下栏高约 64px）
    python3 -c "from PIL import Image; im=Image.open('$f'); im.crop((0,0,im.width,120)).save('$OUT/$name-top.png')"
    f="$OUT/$name-top.png"
  fi
  echo "$f"
}

cmd_state() {
  need_niri
  niri msg outputs | grep -E "Output|Logical size|Scale"
  echo "-- layers"
  niri msg layers | grep Namespace
  echo "-- windows"
  niri msg windows | grep -E "Window ID|Title|App ID|Tile size"
}

case "${1:-help}" in
  check) cmd_check ;;
  bar) cmd_bar ;;
  ss) shift; cmd_ss "$@" ;;
  state) cmd_state ;;
  msg) need_niri; shift; niri msg "$@" ;;
  *)
    cat <<'EOF'
driver.sh check            校验：niri 配置、脚本、链接、dconf.ini、quickshell 能否加载
driver.sh bar              重启顶栏（quickshell；没有则 waybar），日志 $OUT/bar.log
driver.sh ss [名字] [top]  截整屏到 $OUT/名字.png；加 top 另存只含顶栏的裁剪图
driver.sh state            输出、图层（顶栏/壁纸）、窗口列表
driver.sh msg <参数…>      直接转给 niri msg（已设好 NIRI_SOCKET）
环境变量：OUT（默认 /tmp/dotfiles-driver）、QS_ROOT（解压的 quickshell RPM 根目录）
EOF
    ;;
esac
