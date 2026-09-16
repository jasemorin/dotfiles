#!/usr/bin/env bash
# 在新机器上把本仓库的配置链接到 ~/.config
# 用法: ./install.sh [--dry-run]
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

link() {
  local src="$DOTFILES/config/$1"
  local dst="$TARGET/$1"

  if [[ ! -e "$src" ]]; then
    echo "跳过 $1：仓库中不存在"
    return
  fi

  # 已经指向正确位置，无需操作
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo "已就位 $1"
    return
  fi

  # 已存在真实文件/目录：先备份，不直接删除
  if [[ -e "$dst" || -L "$dst" ]]; then
    local backup="$dst.backup.$(date +%Y%m%d%H%M%S)"
    echo "备份 $dst -> $backup"
    $DRY_RUN || mv "$dst" "$backup"
  fi

  echo "链接 $dst -> $src"
  $DRY_RUN || ln -s "$src" "$dst"
}

mkdir -p "$TARGET"
for name in "$DOTFILES"/config/*/; do
  link "$(basename "$name")"
done

echo
echo "完成。kitty 需要完全退出后重开；nvim 下次启动时 lazy.nvim 会自动装插件。"
