# dotfiles

kitty、Neovim 以及 Asahi Linux（niri 桌面）的个人配置，通过符号链接部署到 `~/.config`。
Mac 和 Asahi 两台机器共用；只属于一边的设置分开放（见下方「Mac / Linux 分开」）。

## 文档

- [docs/keybindings.md](docs/keybindings.md)：键位速查（Caps 层 / Cmd / kitty / shell）
- [docs/setup-asahi.md](docs/setup-asahi.md)：Asahi 上从零部署
- [docs/troubleshooting.md](docs/troubleshooting.md)：踩过的坑和解决办法
- [docs/memory.md](docs/memory.md)：内存管理（zswap、Firefox、电源模式）
- [docs/gaming.md](docs/gaming.md)：在 Asahi 上玩游戏（Steam、原生游戏、云游戏）

## 结构

```
config/
  kitty/    -> ~/.config/kitty
  nvim/     -> ~/.config/nvim
  niri/     -> ~/.config/niri     （Linux：平铺窗口管理器）
  waybar/   -> ~/.config/waybar   （niri 下的状态栏）
  fuzzel/   -> ~/.config/fuzzel   （niri 下的启动器）
  mako/     -> ~/.config/mako     （旧的通知守护进程，已换成 swaync，配置保留）
  swaync/   -> ~/.config/swaync   （niri 下的通知 + 右上角快捷设置面板）
  swaylock/ -> ~/.config/swaylock （niri 下的锁屏样式）
  autostart/ -> ~/.config/autostart（覆盖系统自启动项：niri 下不启动 imsettings）
  fcitx5/   -> ~/.config/fcitx5   （中文输入法：小鹤双拼，Alt+Space 切换）
system/     Linux 上手动部署的文件（不走 install.sh，见 docs/setup-asahi.md）
  keyd/     caps 层、fn 层键位（/etc/keyd/）
  tiny-dfr/ Touch Bar 默认显示媒体键（/etc/tiny-dfr/）
  zswap/    zswap 改用 zstd（/etc/tmpfiles.d/）
  mglru/    内存耗尽时防卡死（/etc/tmpfiles.d/）
  bash/     fzf、zoxide（链接到 ~/.bashrc.d/）
docs/       速查表和指南
backup/original/  改成 GNOME 风格顶栏 + swaync 之前的原始配置（恢复方法见里面的 README）
install.sh  在新机器上建立 config/ 下的链接
```

仓库里的目录名直接对应 `~/.config` 下的名字，`install.sh` 会遍历 `config/*/`
自动链接，所以**新增一个工具的配置只需把目录放进 `config/`**，脚本无需修改。

## 安装

```bash
git clone https://github.com/jasemorin/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run   # 先看会做什么
./install.sh
```

已存在的真实目录会被改名成 `.backup.<时间戳>` 而不是删除。
Asahi 上还有软件包和系统级配置，步骤见 [docs/setup-asahi.md](docs/setup-asahi.md)。

## Mac / Linux 分开

- kitty：共用的放 `kitty.conf`；只给 Linux 的放 `linux.conf`，只给 Mac 的放 `macos.conf`
  （`kitty.conf` 末尾 `include ${KITTY_OS}.conf` 按系统加载）
- `quick-access-terminal.conf` 两边共用且不能按系统加载，只放两边都适用的设置
- niri、waybar、fuzzel、swaync、swaylock、`system/` 只在 Linux 上用
- 改共用文件前先想：这会不会也改变 Mac？

## 依赖

- kitty ≥ 0.48，字体 JetBrains Mono
- Neovim ≥ 0.11（配置用到 `vim.lsp.config` / `vim.hl.on_yank`）
- `shellcheck`、`shfmt`（可选，bashls 靠它出 lint 诊断）
- niri 桌面及工具：完整列表见 [docs/setup-asahi.md](docs/setup-asahi.md)

插件由 lazy.nvim 管理，首次启动 nvim 会自动安装；`lazy-lock.json` 锁定了
精确 commit，纳入版本控制以保证各机器插件版本一致。

## 注意

- kitty 改配置后需**完全退出重开**，`cmd+shift+,` 的 reload 不会重建已有窗口布局。
- 不要把 `~/.config/gh/hosts.yml` 放进来，里面有 GitHub token。
