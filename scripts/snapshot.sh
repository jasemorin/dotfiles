#!/usr/bin/env bash
# 重装前跑一次：把软件包列表和桌面设置（dconf）导出到仓库，再打包个人文件给 iCloud
# 用法: ./scripts/snapshot.sh   （之后检查 git diff 再提交）
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PKG="$DOTFILES/system/packages"
mkdir -p "$PKG"

# 软件包：dnf 手动装的 + flatpak 应用 + COPR 源
dnf repoquery --userinstalled --qf '%{name}\n' 2>/dev/null | sort -u >"$PKG/dnf.txt"
flatpak list --app --columns=application >"$PKG/flatpak.txt"
dnf copr list 2>/dev/null | sed 's|^copr.fedorainfracloud.org/||' >"$PKG/copr.txt"
echo "软件包：$(wc -l <"$PKG/dnf.txt") 个 dnf，$(wc -l <"$PKG/flatpak.txt") 个 flatpak"

# dconf：去掉窗口状态、定位坐标、网络连接等机器专属项（仓库是公开的）
{
  echo '# 桌面设置（dconf），已去掉窗口状态、定位坐标等机器专属项'
  echo '# 恢复：dconf load / < ~/dotfiles/system/dconf.ini'
  echo
  dconf dump / |
    # login-screen 被系统锁定，dconf load 会报错
    awk '/^\[/{skip = ($0 ~ /window-state|file-chooser|filechooser|gnome-system-monitor|nm-applet|control-center|org\/gnome\/calendar|org\/gnome\/software|app-folders|settings-daemon\/plugins\/color|color-chooser|org\/gnome\/Ptyxis|notifications|world-clocks|nautilus|login-screen/)} !skip' |
    grep -vE 'last-selected|welcome-dialog' | cat -s
} >"$DOTFILES/system/dconf.ini"
echo "dconf：已导出到 system/dconf.ini"

# 个人文件：打包到 ~，手动传到 icloud.com → 云盘
OUT="$HOME/home-backup-$(date +%Y%m%d).tar.gz"
cd "$HOME"
tar czf "$OUT" --ignore-failed-read \
  Documents Desktop Pictures Music Videos Downloads Templates \
  .local/share/fonts \
  .claude/settings.json .claude/CLAUDE.md .claude/skills .claude/plans .claude/projects/*/memory \
  2>/dev/null || true
echo "个人文件：$OUT（$(du -h "$OUT" | cut -f1)）"
echo
echo "下一步：cd $DOTFILES && git status && git diff，确认后提交推送"
