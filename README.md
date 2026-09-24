# dotfiles

kitty 与 Neovim 的个人配置，通过符号链接部署到 `~/.config`。

## 结构

```
config/
  kitty/    -> ~/.config/kitty
  nvim/     -> ~/.config/nvim
  niri/     -> ~/.config/niri     （Linux：平铺窗口管理器）
  waybar/   -> ~/.config/waybar   （niri 下的状态栏）
  fuzzel/   -> ~/.config/fuzzel   （niri 下的启动器）
  mako/     -> ~/.config/mako     （niri 下的通知）
system/
  keyd/     系统级，需手动部署（caps 层，见下方「键位约定」）
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

Linux 上还需手动部署 keyd（系统级，不走 `install.sh`）：

```bash
sudo cp ~/dotfiles/system/keyd/default.conf /etc/keyd/ && sudo keyd reload
```

## 键位约定（Linux / niri）

一个修饰键只管一类事：

| 按键 | 作用 |
|---|---|
| Caps 单击 | Esc |
| Caps 按住 + 窗口键 | niri 窗口管理（keyd 发出 `ctrl+alt+super+键`） |
| Caps 按住 + 其他键 | Ctrl |
| 物理 Control | 普通 Ctrl，不受影响（Control+L 清屏、nvim 的 Control+hjkl 等） |
| Cmd | macOS 式命令：Cmd+Space 启动器、Cmd+Q 关窗口、Cmd+Shift+3/4/5 截图、kitty 标签页、Cmd+C/V、Cmd+K 清屏 |
| Alt | 不占用，留给终端和应用 |

Caps 层的窗口键（加 Shift 为括号内动作）：

- `h j k l` 切焦点（移动窗口）
- `1-9` 切工作区（把窗口送过去）；再按当前工作区的数字回到上一个
- `,` `.` 列变窄 / 变宽（调高度）
- `'` 轮换列宽预设（在浮动/平铺间切焦点）
- `m` 最大化（全屏）
- `[` `]` 把窗口并入 / 拆出相邻列
- `;` 同列窗口叠成标签（切换浮动）
- `` ` `` 概览
- `Enter` 新开 kitty（下拉终端）
- `Shift+/` 显示全部快捷键；`Esc` 应用抢占快捷键时恢复

新增窗口键时，`system/keyd/default.conf` 和 `config/niri/config.kdl` 两边都要改。
kitty 的分屏键位只在 macOS 加载（`config/kitty/macos.conf`），Linux 上分屏交给 niri。

## 依赖

- kitty ≥ 0.48，字体 JetBrains Mono
- Neovim ≥ 0.11（配置用到 `vim.lsp.config` / `vim.hl.on_yank`）
- `shellcheck`、`shfmt`（可选，bashls 靠它出 lint 诊断）

插件由 lazy.nvim 管理，首次启动 nvim 会自动安装；`lazy-lock.json` 锁定了
精确 commit，纳入版本控制以保证各机器插件版本一致。

## 注意

- kitty 改配置后需**完全退出重开**，`cmd+shift+,` 的 reload 不会重建已有窗口布局。
- 不要把 `~/.config/gh/hosts.yml` 放进来，里面有 GitHub token。
