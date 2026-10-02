#!/usr/bin/env bash
# 重装后一键恢复：软件包、配置链接、系统级配置、桌面设置、个人文件
# 新系统上直接运行（会自动 clone 仓库）：
#   bash <(curl -fsSL https://raw.githubusercontent.com/jasemorin/dotfiles/asahi/restore.sh)
# 或在仓库里：./restore.sh [--dry-run]
# 可重复运行，已完成的步骤会跳过。步骤说明见 docs/reinstall.md
set -euo pipefail

REPO=https://github.com/jasemorin/dotfiles.git
BRANCH=asahi
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# 通过 curl 运行时还没有仓库：先 clone，再用仓库里的脚本继续
SELF="${BASH_SOURCE[0]}"
if [[ ! -f "$(dirname "$SELF")/install.sh" ]]; then
  command -v git >/dev/null || sudo dnf install -y git
  [[ -d ~/dotfiles/.git ]] || git clone -b "$BRANCH" "$REPO" ~/dotfiles
  exec ~/dotfiles/restore.sh "$@"
fi
DOTFILES="$(cd "$(dirname "$SELF")" && pwd)"
cd "$DOTFILES"

step() { printf '\n\033[1;35m==> %s\033[0m\n' "$*"; }
run() {
  echo "+ $*"
  $DRY_RUN || "$@"
}
# 复制系统文件：内容相同则跳过
put() {
  local src="$DOTFILES/system/$1" dst="$2"
  if cmp -s "$src" "$dst" 2>/dev/null; then
    echo "已就位 $dst"
  else
    run sudo install -Dm644 "$src" "$dst"
  fi
}
# 用户级链接：已正确则跳过，已存在的真实文件先备份
link() {
  local src="$1" dst="$2"
  [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]] && { echo "已就位 $dst"; return; }
  [[ -e "$dst" || -L "$dst" ]] && run mv "$dst" "$dst.backup.$(date +%Y%m%d%H%M%S)"
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
}

# 开头输一次密码，之后保持 sudo 有效
if ! $DRY_RUN; then
  sudo -v
  while sleep 50; do sudo -n true; kill -0 $$ 2>/dev/null || exit; done 2>/dev/null &
  trap 'kill $! 2>/dev/null' EXIT
fi

step "软件包"
while read -r copr; do
  [[ -z "$copr" ]] && continue
  if dnf copr list 2>/dev/null | grep -q "/$copr$"; then
    echo "已启用 COPR $copr"
  else
    run sudo dnf copr enable -y "$copr"
  fi
done <system/packages/copr.txt
mapfile -t pkgs <system/packages/dnf.txt
run sudo dnf install -y --skip-unavailable "${pkgs[@]}"
if [[ -s system/packages/flatpak.txt ]]; then
  mapfile -t apps <system/packages/flatpak.txt
  run flatpak install -y --noninteractive flathub "${apps[@]}"
fi

step "配置链接（~/.config）"
if $DRY_RUN; then ./install.sh --dry-run; else ./install.sh; fi

step "个人脚本、bash、通知服务"
link "$DOTFILES/scripts/steam-arm64.sh" ~/.local/bin/steam-arm64
link "$DOTFILES/scripts/reboot-macos.sh" ~/.local/bin/reboot-macos
link "$DOTFILES/system/bash/tools.sh" ~/.bashrc.d/tools.sh
# 有程序发通知但没有通知服务时自动启动的程序：通知由 Quickshell 负责（它和顶栏一起由 niri 启动），
# 这里只在没装 quickshell 时启动 swaync；否则 quickshell 重启的间隙会被 swaync 抢走通知服务
dbus=~/.local/share/dbus-1/services/org.freedesktop.Notifications.service
dbus_text='# 通知服务的 D-Bus 自动启动：装了 quickshell 就不启动（通知由它负责），否则启动 swaync（而不是 mako）
[D-BUS Service]
Name=org.freedesktop.Notifications
Exec=/usr/bin/sh -c "command -v qs >/dev/null || exec /usr/bin/swaync"'
if [[ "$(cat "$dbus" 2>/dev/null)" == "$dbus_text" ]]; then
  echo "已就位 $dbus"
else
  run mkdir -p "$(dirname "$dbus")"
  $DRY_RUN || printf '%s\n' "$dbus_text" >"$dbus"
fi
git config --global user.name >/dev/null || run git config --global user.name jasemorin
git config --global user.email >/dev/null || run git config --global user.email 90958862+jasemorin@users.noreply.github.com

step "系统级配置（/etc）"
put keyd/default.conf /etc/keyd/default.conf
if [[ ! -f /etc/systemd/system/keyd.service.d/restart.conf ]]; then
  run sudo mkdir -p /etc/systemd/system/keyd.service.d
  $DRY_RUN || printf '[Service]\nRestart=on-failure\nRestartSec=1\n' | sudo tee /etc/systemd/system/keyd.service.d/restart.conf >/dev/null
  run sudo systemctl daemon-reload
fi
run sudo systemctl enable keyd
run sudo systemctl restart keyd
put tiny-dfr/config.toml /etc/tiny-dfr/config.toml
run sudo systemctl restart tiny-dfr || true
put zswap/zswap-zstd.conf /etc/tmpfiles.d/zswap-zstd.conf
put mglru/mglru.conf /etc/tmpfiles.d/mglru.conf
run sudo systemd-tmpfiles --create /etc/tmpfiles.d/zswap-zstd.conf /etc/tmpfiles.d/mglru.conf
# 第二个 8 GB 交换文件（安装时自带的只有 8 GB，Steam + Firefox 会把它用光，程序接连被 OOM 结束，见 memory.md）
if [[ -f /var/swap/swapfile2 ]]; then
  echo "已就位 /var/swap/swapfile2"
else
  run sudo btrfs filesystem mkswapfile --size 8G /var/swap/swapfile2
fi
grep -q '^/var/swap/swapfile2 ' /etc/fstab || { $DRY_RUN && echo "+ 把 swapfile2 加进 /etc/fstab" || echo '/var/swap/swapfile2 swap swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null; }
swapon --show=NAME --noheadings | grep -q swapfile2 || run sudo swapon /var/swap/swapfile2
for f in system/tuned/gaming/*; do put "tuned/gaming/$(basename "$f")" "/etc/tuned/profiles/gaming/$(basename "$f")"; done
# 通过 tuned-ppd 切到「平衡」（用电池时对应 balanced-battery）；直接 tuned-adm profile balanced 会让
# PowerProfiles 接口报 unknown，顶栏快捷设置面板就认不出当前模式
run busctl --system set-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile s balanced

step "xwayland-satellite ≥ 0.8.3（修 Steam 菜单闪退，见 troubleshooting.md）"
have=$(rpm -q --qf '%{version}' xwayland-satellite 2>/dev/null || echo 0)
if [[ "$(printf '%s\n' 0.8.3 "$have" | sort -V | head -1)" == 0.8.3 ]]; then
  echo "系统版本 $have 已够新：可以删掉 niri 配置里的 xwayland-satellite { path ... }"
elif [[ -x ~/.local/bin/xwayland-satellite ]]; then
  echo "已就位 ~/.local/bin/xwayland-satellite"
else
  run sudo dnf install -y cargo clang libxcb-devel xcb-util-cursor-devel
  src=~/.local/src/xwayland-satellite
  [[ -d "$src" ]] || run git clone -b v0.8.3 https://github.com/Supreeeme/xwayland-satellite.git "$src"
  if ! $DRY_RUN; then
    (cd "$src" && cargo build --release)
    install -Dm755 "$src/target/release/xwayland-satellite" ~/.local/bin/xwayland-satellite
  fi
fi

step "桌面设置（dconf）"
if $DRY_RUN; then echo "+ dconf load / < system/dconf.ini"; else dconf load / <system/dconf.ini; fi

step "个人文件（从 iCloud 下载的备份包）"
# shellcheck disable=SC2012  # 文件名是固定格式，ls -t 取最新的即可
backup=$(ls -t ~/Downloads/home-backup-*.tar.gz ~/home-backup-*.tar.gz 2>/dev/null | head -1 || true)
if [[ -n "$backup" ]]; then
  run tar xzf "$backup" -C ~ --skip-old-files
  run fc-cache -f
else
  echo "没找到 ~/Downloads/home-backup-*.tar.gz：从 icloud.com 下载后重新运行本脚本即可"
fi
# shellcheck disable=SC2012
wifi=$(ls -t ~/Downloads/wifi.tgz ~/wifi.tgz 2>/dev/null | head -1 || true)
if [[ -n "$wifi" ]]; then
  run sudo tar xzf "$wifi" -C /
  run sudo systemctl restart NetworkManager
fi

step "顶栏图标字体 Symbols Nerd Font"
if [[ -n "$(fc-list "Symbols Nerd Font")" ]]; then
  echo "已安装"
elif ! $DRY_RUN; then
  mkdir -p ~/.local/share/fonts/NerdFontsSymbolsOnly
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/NerdFontsSymbolsOnly.tar.xz |
    tar xJ -C ~/.local/share/fonts/NerdFontsSymbolsOnly
  fc-cache -f
else
  echo "+ 下载 NerdFontsSymbolsOnly.tar.xz 到 ~/.local/share/fonts"
fi

step "GitHub 登录"
if gh auth status >/dev/null 2>&1; then
  echo "已登录"
elif [[ -t 0 ]] && ! $DRY_RUN; then
  gh auth login && gh auth setup-git
  git -C "$DOTFILES" remote set-url origin "$REPO"
else
  echo "稍后运行：gh auth login && gh auth setup-git"
fi

step "完成"
cat <<'EOF'
剩下手动的：
  - Firefox 登录 Sync
  - 注销，登录界面齿轮里选 niri
  - 检查：niri validate；systemctl is-active keyd；tuned-adm active
EOF
