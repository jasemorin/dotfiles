# dotfiles

kitty 与 Neovim 的个人配置，通过符号链接部署到 `~/.config`。

## 结构

```
config/
  kitty/      -> ~/.config/kitty
  nvim/       -> ~/.config/nvim
  karabiner/  -> ~/.config/karabiner    键盘改造（Caps Lock 双重身份 / Hyper 键）
  aerospace/  -> ~/.config/aerospace    平铺窗口管理，官方默认配置（alt 键位）
  git/        -> ~/.config/git          全局 gitignore
  rstudio/    -> ~/.config/rstudio      RStudio 偏好与自定义 CSS
install.sh  在新机器上建立上述链接
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

## 键盘化分层

| 层 | 工具 | 配置位置 |
| --- | --- | --- |
| 按键改造 | Karabiner-Elements | `config/karabiner/` |
| 窗口管理 | AeroSpace | `config/aerospace/` |
| 终端 | kitty | `config/kitty/` |
| 编辑器 | Neovim + LazyVim | `config/nvim/` |

AeroSpace 用官方默认配置（`alt-hjkl` 移焦点、`alt-数字/字母` 切工作区、`alt-shift-;` 进 service 模式）。
Karabiner 里的 Hyper 键（按住右 Cmd）目前没有被 AeroSpace 使用，留着给以后用。

## 注意

- kitty 改配置后需**完全退出重开**，`cmd+shift+,` 的 reload 不会重建已有窗口布局。
- 不要把 `~/.config/gh/hosts.yml` 放进来，里面有 GitHub token。
- Karabiner 改完配置**立即生效**，它会监听 `karabiner.json` 的变化，不用重启。
- AeroSpace 改完跑 `aerospace reload-config`（或按 Hyper-0）。
- AeroSpace 优先读 `~/.aerospace.toml`，**其次**才是 `~/.config/aerospace/aerospace.toml`。
  如果前者存在，本仓库的配置不会生效 —— 删掉或改名它。
