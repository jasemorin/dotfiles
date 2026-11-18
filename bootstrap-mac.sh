#!/usr/bin/env bash
# 新 Mac 一键恢复：命令行工具 → Homebrew → Brewfile 里的软件 → 配置链接 → SDKMAN + JDK 21
# 用法：
#   git clone https://github.com/jasemorin/dotfiles.git ~/dotfiles
#   cd ~/dotfiles && git checkout lazyvim && ./bootstrap-mac.sh
# 可以重复运行，已经装好的步骤会自动跳过。
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
step() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }

step "1/5 Xcode 命令行工具"
if ! xcode-select -p >/dev/null 2>&1; then
  xcode-select --install || true
  echo "弹窗里点「安装」，装完后重新运行 ./bootstrap-mac.sh"
  exit 0
fi
echo "已安装"

step "2/5 Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || brew shellenv)"
grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null || \
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"

step "3/5 Brewfile 里的软件"
if [[ -f "$DOTFILES/Brewfile" ]]; then
  brew bundle --file="$DOTFILES/Brewfile" || echo "有个别软件没装上，看上面的报错，之后可以单独 brew install"
else
  echo "仓库里没有 Brewfile，跳过"
fi

step "4/5 链接配置到 ~/.config"
"$DOTFILES/install.sh"

step "5/5 SDKMAN + JDK 21（jdtls 需要）"
if [[ ! -d "$HOME/.sdkman" ]]; then
  curl -s "https://get.sdkman.io" | bash
fi
set +u
source "$HOME/.sdkman/bin/sdkman-init.sh"
if ! sdk current java 2>/dev/null | grep -q ' 21\.'; then
  ID="$(PAGER=cat sdk list java | grep -oE '21\.[0-9]+\.[0-9]+-tem' | head -1)"
  if [[ -n "$ID" ]]; then
    sdk install java "$ID" </dev/null
  else
    echo "没找到 JDK 21 版本号，手动运行：sdk list java，再 sdk install java <21 开头的 -tem 版本>"
  fi
fi
set -u

cat <<'DONE'

全部完成。还需要你手动做的：
  • gh auth login                        （GitHub 登录，token 不放在仓库里）
  • 打开 Karabiner-Elements、窗口管理器、Raycast，按提示在
    系统设置 → 隐私与安全性 里给「输入监控」「辅助功能」权限
  • Raycast 登录账号，设置会从云端同步
  • kitty 完全退出再打开；第一次开 nvim 会自动装插件
DONE
