# Asahi Linux（Fedora Asahi Remix）从零部署

适用：MacBook Pro 13" M2，Fedora Asahi Remix 44，niri 桌面。Mac 上只需要第 2 步。
重装（已有 `system/packages/` 快照）的话直接看 [reinstall.md](reinstall.md)。

## 1. 安装软件包

```bash
# niri 桌面
sudo dnf install niri xwayland-satellite waybar fuzzel SwayNotificationCenter swaybg swayidle swaylock \
  brightnessctl playerctl mate-polkit cliphist wl-clipboard jetbrains-mono-fonts-all
# 中文输入法（小鹤双拼）；不装 fcitx5-autostart，由 niri 启动
sudo dnf install fcitx5 fcitx5-chinese-addons fcitx5-gtk fcitx5-qt fcitx5-configtool
# 终端工具
sudo dnf install fzf zoxide ShellCheck shfmt
# keyd（不在官方源，用 COPR）
sudo dnf copr enable alternateved/keyd
sudo dnf install keyd
```

顶栏图标字体 Symbols Nerd Font：从 nerd-fonts 的 releases 下载 `NerdFontsSymbolsOnly.tar.xz`，
解压到 `~/.local/share/fonts/` 后 `fc-cache -f`。

## 2. 链接配置（Mac 和 Linux 都要）

```bash
git clone https://github.com/jasemorin/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run   # 先看会做什么
./install.sh             # 把 config/*/ 链接到 ~/.config
```

已存在的真实目录会被改名成 `.backup.<时间戳>` 而不是删除。

## 3. 系统级配置（需要 sudo，不走 install.sh）

```bash
# keyd：caps 层
sudo systemctl enable --now keyd
sudo cp ~/dotfiles/system/keyd/default.conf /etc/keyd/
sudo systemctl restart keyd      # 用 restart 而不是 keyd reload，后者可能崩溃（见 troubleshooting.md）

# keyd 崩溃后自动重启
sudo mkdir -p /etc/systemd/system/keyd.service.d
printf '[Service]\nRestart=on-failure\nRestartSec=1\n' | sudo tee /etc/systemd/system/keyd.service.d/restart.conf
sudo systemctl daemon-reload

# Touch Bar 默认显示媒体键（F1-F12 用 keyd 的 fn+数字行）
sudo mkdir -p /etc/tiny-dfr && sudo cp ~/dotfiles/system/tiny-dfr/config.toml /etc/tiny-dfr/
sudo systemctl restart tiny-dfr

# zswap 改用 zstd 压缩（不用重启）
sudo cp ~/dotfiles/system/zswap/zswap-zstd.conf /etc/tmpfiles.d/
sudo systemd-tmpfiles --create /etc/tmpfiles.d/zswap-zstd.conf

# MGLRU（min_ttl_ms=0，原因见 docs/memory.md）
sudo cp ~/dotfiles/system/mglru/mglru.conf /etc/tmpfiles.d/
sudo systemd-tmpfiles --create /etc/tmpfiles.d/mglru.conf

# 电源模式：平衡（不要用 throughput-performance，见 memory.md；游戏用 gaming，见 gaming.md）
sudo cp -r ~/dotfiles/system/tuned/gaming /etc/tuned/profiles/
# 通过 tuned-ppd 切换，PowerProfiles 接口（顶栏快捷设置面板）才认得出当前模式
busctl --system set-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile s balanced
```

## 4. 用户级设置

```bash
# bash 增强（fzf、zoxide）
mkdir -p ~/.bashrc.d && ln -s ~/dotfiles/system/bash/tools.sh ~/.bashrc.d/tools.sh

# git 身份
git config --global user.name jasemorin
git config --global user.email 90958862+jasemorin@users.noreply.github.com

# GitHub 登录（推送用）
sudo dnf install gh && gh auth login && gh auth setup-git
```

让通知总是由 swaync 而不是 mako 自动启动：新建
`~/.local/share/dbus-1/services/org.freedesktop.Notifications.service`，内容为：

```ini
[D-BUS Service]
Name=org.freedesktop.Notifications
Exec=/usr/bin/swaync
```

Firefox 内存设置见 [memory.md](memory.md)。

## 5. 进入 niri

注销，在登录界面点齿轮选 **niri**。进去后按 Caps+Shift+/ 看快捷键，完整列表见 [keybindings.md](keybindings.md)。

## 检查清单

```bash
niri validate                                   # niri 配置无误
systemctl is-active keyd                        # active
cat /sys/module/zswap/parameters/compressor    # zstd
cat /sys/kernel/mm/lru_gen/min_ttl_ms          # 0
tuned-adm active                                # balanced
pgrep -a polkit-mate                            # 密码弹窗代理在跑
pgrep -af 'cliphist store'                      # 剪贴板历史在记录
```
