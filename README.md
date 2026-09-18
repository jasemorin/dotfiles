# dotfiles

kitty 与 Neovim 的个人配置，通过符号链接部署到 `~/.config`。

## 结构

```
config/
  kitty/    -> ~/.config/kitty
  nvim/     -> ~/.config/nvim
install.sh  在新机器上建立上述链接
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

- kitty ≥ 0.48，字体 JetBrains Mono（需 Nerd Font 图标变体）
- Neovim ≥ 0.11
- `git`、`ripgrep`、`fd`、`lazygit`（LazyVim 的搜索与 git 界面依赖）
- `shellcheck`、`shfmt`（可选，bashls 靠它出 lint 诊断）
- JDK ≥ 21（jdtls 自身需要，与项目使用的 Java 版本无关）

Neovim 配置基于 **LazyVim**：`lua/config/` 与 `lua/plugins/` 里只写与 LazyVim
默认值不同的部分，其余交给 LazyVim。启用的 extras 列在 `lua/config/lazy.lua`，
也可用 `:LazyExtras` 增删。插件由 lazy.nvim 管理，首次启动 nvim 会自动安装；
`lazy-lock.json` 锁定了精确 commit，纳入版本控制以保证各机器插件版本一致。

首次启动后跑一次 `:LazyHealth` 检查依赖是否齐全。

## 注意

- kitty 改配置后需**完全退出重开**，`cmd+shift+,` 的 reload 不会重建已有窗口布局。
- 不要把 `~/.config/gh/hosts.yml` 放进来，里面有 GitHub token。
