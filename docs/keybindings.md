# 键位速查

> Caps 层窗口管理两台机器通用：Linux 是 keyd + niri，Mac 是 Karabiner + OmniWM（同样发 `⌃⌥⌘+键`）。
> kitty 的 Cmd 键位也两边通用。只在一边有的已标注。
> 随时按 **Caps+Shift+/**：niri 显示全部快捷键，OmniWM 打开命令面板。

## 总原则：一个修饰键只管一类事

| 按键 | 作用 |
|---|---|
| Caps 单击 | Esc |
| 左 Shift + 右 Shift | 大小写锁定（再按一次关闭；两边都有） |
| Caps 按住 + 窗口键 | 窗口管理（keyd / Karabiner 发出 `ctrl+alt+super+键` / `⌃⌥⌘+键`）；Karabiner 的 AeroSpace profile 没有这一层，Caps 按住就是普通 Ctrl |
| Caps 按住 + 其他键 | Ctrl（Caps+C 中断、Caps+R 搜历史、Firefox 里 Caps+T 新标签等） |
| 物理 Control | 普通 Ctrl，不受 keyd / Karabiner 影响（Control+L 清屏、nvim 的 Control+hjkl 等） |
| HHKB 右 Option | HHKB 没有物理 Control（Caps 位的 Control 就是 Caps 层），由它充当上面的普通 Ctrl |
| Caps 按住 + Cmd + 窗口键 | 不进窗口层，原样发 `⌃⌘+键` 给前台应用（kitty 的分屏 / 标签页移动） |
| Cmd | macOS 式的应用 / 系统命令 |
| Alt | 不占用，留给终端和应用（Alt+b/f 按词跳、Alt+C 模糊 cd） |
| Alt+Space | 中英文输入切换（fcitx5 小鹤双拼，Linux） |

## Caps 层（按住 Caps；niri / OmniWM）

| 按键 | 作用 | 加 Shift |
|---|---|---|
| `h` / `l` | 焦点移到左 / 右列 | 把整列往左 / 右移 |
| `j` / `k` | 焦点移到下 / 上窗口（到头切工作区） | 窗口往下 / 上移（到头移到相邻工作区） |
| `1`–`9` | 切到工作区；再按一次当前数字回到上一个（仅 Linux；Mac 用 Caps+Tab） | 把当前列送过去 |
| `,` / `.` | 列变窄 / 变宽 10% | 窗口变矮 / 变高 10% |
| `'` | 轮换列宽（⅓ → ½ → ⅔ → 全宽） | 在浮动 / 平铺窗口间切焦点（仅 Linux） |
| `m` | 最大化列 | 全屏 |
| `[` / `]` | 把窗口并入左 / 右列，或拆出来 | — |
| `;` | 同列窗口叠成标签 | 切换浮动 |
| `` ` `` | 概览（类似 Mission Control） | — |
| `Enter` | 新开 kitty | 下拉终端（再按一次收起；Mac 上是 OmniWM 的 quake 终端） |
| `Tab` | 回到上一个工作区（仅 Mac） | — |
| `/` | — | 显示全部快捷键（Mac：OmniWM 命令面板） |
| `Esc` | 应用抢占快捷键时恢复（仅 Linux） | 重启进 macOS（仅 Linux，只这一次，弹密码框确认） |

新增窗口键时要改四处：Linux 的 `system/keyd/default.conf` + `config/niri/config.kdl`，
Mac 的 `config/karabiner/karabiner.json`（「Caps 层窗口键」规则）+ `~/.config/omniwm/settings.toml`（`[[hotkeys]]`）。

Mac 上的几个例外（Karabiner 直接调用 `omniwmctl`，不发热键）：
- Caps+`[` / `]`：OmniWM 没有「并入或拆出」的热键，只有 CLI 命令。
- Caps+Shift+`,` / `.`：`⌃⌥⇧⌘+.` 会触发系统 sysdiagnose，不能当热键发。
- Caps+Enter：`open -na kitty`。

## 40% 外接键盘（44 键 Vial，仅 Mac / Karabiner）

> 规则都带 `device_unless is_built_in_keyboard`，只对外接键盘生效；MacBook 自带键盘不受影响。
> 固件现状：键帽「Esc」发 Tab，键帽「Tab」发 Esc，右 Alt 发 ←，最右键发 →，两个空格都发空格，Fn 是固件层键（电脑收不到，别乱按 Fn 组合）。

| 按键 | 作用 |
|---|---|
| 印「Tab」的键（发 Esc）轻按 / 按住 | Esc 并清零层状态 / Control + Caps 窗口层（同 MacBook 的 Caps） |
| 印「Esc」的键 | 普通 Tab |
| 按住空格 + 键 | 符号层（先松字母、后松空格才算；打字连按照常出空格） |
| 右 Alt 轻按 / 按住 | ← / 导航层 |
| 最右键 | 普通 → |
| 右 Shift（固件轻按发 /） | 永远是右 Shift；`/` 用空格+L |

符号层（按住空格，加 Shift 得上档符号，如 Shift+j = `:`）：

| | Q | W | E | R | T | Y | U | I | O | P |
|---|---|---|---|---|---|---|---|---|---|---|
| 行 1 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 0 |

| | A | S | D | F | G | H | J | K | L |
|---|---|---|---|---|---|---|---|---|---|
| 行 2 | `` ` `` | `-` | `=` | `[` | `]` | `\` | `;` | `'` | `/` |

行 3：N = `(`，M = `)`，`,` = `{`，`.` = `}`

导航层（按住右 Alt）：

| 按键 | 作用 |
|---|---|
| h j k l | ← ↓ ↑ → |
| n / m / , / . | Home / PgDn / PgUp / End |
| q … p，a，s | F1 … F10，F11，F12 |
| Back | 向后删除（Del） |
| z / x / c / v | 静音 / 音量- / 音量+ / 播放暂停 |

Caps 层里 40% 上没有的键（数字、`; ' [ ] / ``）：**按住 Esc 键（印 Tab）+ 按住空格**，再按符号层上对应位置。
例：Esc 键+空格+e = 工作区 3，+k = 轮换列宽（`'`），+j = 叠成标签（`;`）。

层卡住（字母变数字/符号）时：轻按一下 Esc 键即可清零。

## niri：Cmd

| 按键 | 作用 |
|---|---|
| Cmd+Space | 启动器（类似 Spotlight） |
| Cmd+Shift+V | 剪贴板历史（选中后 Cmd+V / Caps+V 粘贴） |
| Cmd+Q | 关闭窗口 |
| Cmd+Ctrl+Q | 锁屏 |
| Cmd+Shift+3 / 4 / 5 | 截图：全屏 / 选区 / 窗口（存到 `~/Pictures/Screenshots`，同时复制到剪贴板） |
| Cmd+滚轮 上下 / 左右 | 切工作区 / 切列 |
| 按住 Cmd 拖动 | 移动窗口 |

其他：Touch Bar 默认显示媒体键（屏幕亮度、键盘背光、音量、播放）；Ctrl+Alt+Delete 退出 niri；鼠标悬停即聚焦（只对完全在屏幕内的窗口）。

## fn（Linux，keyd 提供，同 macOS）

| 按键 | 作用 |
|---|---|
| fn+1 … fn+0、fn+-、fn+= | F1 … F12 |
| fn+↑ / fn+↓ | Page Up / Page Down |
| fn+← / fn+→ | Home / End |
| fn+Delete | 向后删除 |

Touch Bar 不会随 fn 切换（原因见 troubleshooting.md），一直显示媒体键。

## kitty（Cmd，两台机器通用）

| 按键 | 作用 |
|---|---|
| Cmd+T / Cmd+W | 新标签 / 关标签 |
| Cmd+1–5、Cmd+Shift+[ ] | 切标签 |
| Cmd+Shift+T | 从列表选标签（**仅 Linux**；Mac 上是把分屏拆成标签） |
| Cmd+C / Cmd+V | 复制 / 粘贴 |
| Cmd+K | 清屏（**仅 Linux**；Mac 上是 Cmd+Alt+K） |
| Cmd+↑ / ↓ | 跳到上一个 / 下一个命令提示符 |
| Cmd+Shift+↑ / ↓ | 回滚到顶部 / 底部 |
| Cmd+F | 搜索回滚 |
| Cmd+G | 查看上一条命令的完整输出 |
| Cmd+E（+Shift） | 打开链接（复制链接） |
| Cmd+O（+Shift） | 打开文件路径（插入到命令行） |
| Cmd+= / Cmd+- / Cmd+0 | 字号放大 / 缩小 / 还原 |

分屏：Linux 上交给 niri（每个 kitty 窗口就是一个 niri 窗口）；Mac 上的 Cmd+D 等分屏键位见 `config/kitty/macos.conf`。

## Shell（Linux 的 bash，见 `system/bash/tools.sh`）

| 按键 / 命令 | 作用 |
|---|---|
| Caps+R | 模糊搜索命令历史（fzf） |
| Caps+T | 模糊找文件，插入到命令行（fzf） |
| Alt+C | 模糊选目录并 cd（fzf） |
| `z 名字` | 跳到常去的目录（zoxide，会记住你去过的地方） |
| `zi` | 交互选择常去的目录 |
| Control+L | 清屏（物理 Control 键） |
| Alt+b / Alt+f | 按词左右跳 |
