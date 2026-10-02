# dotfiles

kitty、Neovim 以及 Asahi Linux（niri 桌面）的个人配置，通过符号链接部署到 `~/.config`。
Mac 和 Asahi 两台机器共用；只属于一边的设置分开放（见下方「Mac / Linux 分开」）。

## 文档

- [docs/keybindings.md](docs/keybindings.md)：键位速查（Caps 层 / Cmd / kitty / shell）
- [docs/desktop.md](docs/desktop.md)：桌面功能一览（顶栏、快捷设置、通知、电源菜单、锁屏、夜间模式）
- [docs/setup-asahi.md](docs/setup-asahi.md)：Asahi 上从零部署
- [docs/reinstall.md](docs/reinstall.md)：重装系统并保留所有设置（备份到 GitHub + iCloud）
- [docs/troubleshooting.md](docs/troubleshooting.md)：踩过的坑和解决办法
- [docs/memory.md](docs/memory.md)：内存管理（zswap、Firefox、电源模式）
- [docs/gaming.md](docs/gaming.md)：在 Asahi 上玩游戏（Steam、原生游戏、云游戏）
- [docs/disk-space.md](docs/disk-space.md)：从 macOS 让出空间给 Linux

## 结构

```
config/
  kitty/    -> ~/.config/kitty
  nvim/     -> ~/.config/nvim     （LazyVim，两边共用）
  git/      -> ~/.config/git      （全局 gitignore）
  rstudio/  -> ~/.config/rstudio  （RStudio 偏好与自定义 CSS）
  karabiner/ -> ~/.config/karabiner（Mac：键盘改造。Caps：单击 Esc / 按住 Ctrl / 窗口层；右 Cmd = Hyper）
  aerospace/ -> ~/.config/aerospace（Mac：旧的平铺窗口管理配置，已换成 OmniWM，暂留）
  niri/     -> ~/.config/niri     （Linux：平铺窗口管理器）
  quickshell/ -> ~/.config/quickshell（niri 下的顶栏、快捷设置、通知、音量/亮度提示、电源菜单、低电量提醒，背景模糊）
  waybar/   -> ~/.config/waybar   （备用顶栏：没装 quickshell 时启动）
  fuzzel/   -> ~/.config/fuzzel   （niri 下的启动器）
  mako/     -> ~/.config/mako     （旧的通知守护进程，已换成 swaync，配置保留）
  swaync/   -> ~/.config/swaync   （备用通知中心：没装 quickshell 时启动）
  swaylock/ -> ~/.config/swaylock （niri 下的锁屏样式，背景是模糊的壁纸）
  autostart/ -> ~/.config/autostart（覆盖系统自启动项：niri 下不启动 imsettings）
  fcitx5/   -> ~/.config/fcitx5   （中文输入法：小鹤双拼，Alt+Space 切换）
system/     Linux 上手动部署的文件（不走 install.sh，见 docs/setup-asahi.md）
  keyd/     caps 层、fn 层键位（/etc/keyd/）
  tiny-dfr/ Touch Bar 默认显示媒体键（/etc/tiny-dfr/）
  zswap/    zswap 改用 zstd（/etc/tmpfiles.d/）
  mglru/    启用 MGLRU，关闭 min_ttl 防卡死（/etc/tmpfiles.d/）
  tuned/    gaming 电源模式：性能 + 保留 swappiness 60（/etc/tuned/profiles/）
  bash/     fzf、zoxide、eza、bat、starship、历史设置（tools.sh 链接到 ~/.bashrc.d/，inputrc 链接到 ~/.inputrc）
  packages/ dnf / flatpak / COPR 软件包列表（scripts/snapshot.sh 生成）
  dconf.ini 桌面设置（dconf load 恢复）
scripts/    个人脚本（steam-arm64、reboot-macos：链接到 ~/.local/bin/；snapshot.sh：重装前备份）
docs/       速查表和指南
backup/original/  改成 GNOME 风格顶栏 + swaync 之前的原始配置（恢复方法见里面的 README）
install.sh  在新机器上建立 config/ 下的链接
restore.sh  重装后一键恢复全部（软件包 + 链接 + 系统配置 + 个人文件），见 docs/reinstall.md
```

### 刻意不收进来的

| 目录 | 原因 |
| --- | --- |
| `~/.config/github-copilot/` | `apps.json` 里是 **OAuth token**，绝不进仓库 |
| `~/.config/gh/` | `hosts.yml` 里是 GitHub token |
| `~/.config/raycast/` | 405 MB，绝大部分是扩展和缓存；设置本身走 Raycast 自己的云同步 |
| `~/.config/iterm2/` | 只有 socket 和运行时目录，没有配置 |
| `~/.config/cagent/` | 只有本机 uuid 和首次运行标记，换机器没有意义 |

判断标准：**是"我做的选择"就收，是"机器的状态"或"凭据"就不收。**

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
- niri、quickshell、waybar、fuzzel、swaync、swaylock、`system/` 只在 Linux 上用
- karabiner、aerospace 只在 Mac 上用
- 改共用文件前先想：这会不会也改变 Mac？

## 依赖

- kitty ≥ 0.48，字体 JetBrains Mono（需 Nerd Font 图标变体）
- Neovim ≥ 0.11
- `git`、`ripgrep`、`fd`、`lazygit`（LazyVim 的搜索与 git 界面依赖）
- `shellcheck`、`shfmt`（可选，bashls 靠它出 lint 诊断）
- JDK ≥ 21（jdtls 自身需要，与项目使用的 Java 版本无关）
- niri 桌面及工具：完整列表见 [docs/setup-asahi.md](docs/setup-asahi.md)

Neovim 配置基于 **LazyVim**：`lua/config/` 与 `lua/plugins/` 里只写与 LazyVim
默认值不同的部分，其余交给 LazyVim。启用的 extras 列在 `lua/config/lazy.lua`，
也可用 `:LazyExtras` 增删。插件由 lazy.nvim 管理，首次启动 nvim 会自动安装；
`lazy-lock.json` 锁定了精确 commit，纳入版本控制以保证各机器插件版本一致。

首次启动后跑一次 `:LazyHealth` 检查依赖是否齐全。

## 键盘化分层

| 层 | 工具 | 配置位置 |
| --- | --- | --- |
| 按键改造 | Karabiner-Elements | `config/karabiner/` |
| 窗口管理 | OmniWM（niri 布局） | `~/.config/omniwm/settings.toml`（不在仓库，由 app 自己写） |
| 终端 | kitty | `config/kitty/` |
| 编辑器 | Neovim + LazyVim | `config/nvim/` |

键位与 Linux（`asahi` 分支，niri + keyd）一致，完整表格见 [docs/keybindings.md](docs/keybindings.md)：
按住 Caps + 窗口键 → Karabiner 发出 `⌃⌥⌘+键` → OmniWM；加 Shift 就是 `⌃⌥⇧⌘+键`。
Option 不给窗口管理用，留给终端（kitty 里 Option 当 Alt）。
右 Cmd 的 Hyper 同样是 `⌃⌥⇧⌘`，所以 右Cmd+窗口键 = Caps+Shift+窗口键。

## 注意

- kitty 改配置后需**完全退出重开**，`cmd+shift+,` 的 reload 不会重建已有窗口布局。
- 不要把 `~/.config/gh/hosts.yml` 放进来，里面有 GitHub token。
- Karabiner 改完配置**立即生效**，它会监听 `karabiner.json` 的变化，不用重启。
- AeroSpace 改完跑 `aerospace reload-config`（或按 Hyper-0）。
- AeroSpace 优先读 `~/.aerospace.toml`，**其次**才是 `~/.config/aerospace/aerospace.toml`。
  如果前者存在，本仓库的配置不会生效 —— 删掉或改名它。
