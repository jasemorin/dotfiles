# dotfiles

kitty 与 Neovim 的个人配置，通过符号链接部署到 `~/.config`。

## 结构

```
config/
  kitty/    -> ~/.config/kitty
  nvim/     -> ~/.config/nvim
  niri/     -> ~/.config/niri     （Linux：平铺窗口管理器，键位对齐 AeroSpace）
  waybar/   -> ~/.config/waybar   （niri 下的状态栏）
  fuzzel/   -> ~/.config/fuzzel   （niri 下的启动器）
  mako/     -> ~/.config/mako     （niri 下的通知）
system/
  keyd/     系统级，需手动 sudo cp 到 /etc/keyd/（caps lock 按住 ctrl / 单击 esc）
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

## 依赖

- kitty ≥ 0.48，字体 JetBrains Mono
- Neovim ≥ 0.11（配置用到 `vim.lsp.config` / `vim.hl.on_yank`）
- `shellcheck`、`shfmt`（可选，bashls 靠它出 lint 诊断）

插件由 lazy.nvim 管理，首次启动 nvim 会自动安装；`lazy-lock.json` 锁定了
精确 commit，纳入版本控制以保证各机器插件版本一致。

## 注意

- kitty 改配置后需**完全退出重开**，`cmd+shift+,` 的 reload 不会重建已有窗口布局。
- 不要把 `~/.config/gh/hosts.yml` 放进来，里面有 GitHub token。
