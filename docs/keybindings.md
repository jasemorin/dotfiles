# 键位速查

> 窗口管理部分只在 Linux（niri + keyd）上有；kitty 的 Cmd 键位两台机器通用，个别只在一边的已标注。
> 在 niri 里随时按 **Caps+Shift+/** 可以在屏幕上看全部快捷键。

## 总原则：一个修饰键只管一类事

| 按键 | 作用 |
|---|---|
| Caps 单击 | Esc |
| 左 Shift + 右 Shift | 大小写锁定（再按一次关闭；Linux / niri） |
| Caps 按住 + 窗口键 | niri 窗口管理（keyd 发出 `ctrl+alt+super+键`） |
| Caps 按住 + 其他键 | Ctrl（Caps+C 中断、Caps+R 搜历史、Firefox 里 Caps+T 新标签等） |
| 物理 Control | 普通 Ctrl，不受 keyd 影响（Control+L 清屏、nvim 的 Control+hjkl 等） |
| Cmd | macOS 式的应用 / 系统命令 |
| Alt | 不占用，留给终端和应用（Alt+b/f 按词跳、Alt+C 模糊 cd） |
| Alt+Space | 中英文输入切换（fcitx5 小鹤双拼，Linux） |

## niri：Caps 层（按住 Caps）

| 按键 | 作用 | 加 Shift |
|---|---|---|
| `h` / `l` | 焦点移到左 / 右列 | 把整列往左 / 右移 |
| `j` / `k` | 焦点移到下 / 上窗口（到头切工作区） | 窗口往下 / 上移（到头移到相邻工作区） |
| `1`–`9` | 切到工作区；再按一次当前数字回到上一个 | 把当前列送过去 |
| `,` / `.` | 列变窄 / 变宽 10% | 窗口变矮 / 变高 10% |
| `'` | 轮换列宽（⅓ → ½ → ⅔ → 全宽） | 在浮动 / 平铺窗口间切焦点 |
| `m` | 最大化列 | 全屏 |
| `[` / `]` | 把窗口并入左 / 右列，或拆出来 | — |
| `;` | 同列窗口叠成标签 | 切换浮动 |
| `` ` `` | 概览（类似 Mission Control） | — |
| `Enter` | 新开 kitty | 下拉终端（再按一次收起） |
| `/` | — | 显示全部快捷键 |
| `Esc` | 应用抢占快捷键时恢复 | 重启进 macOS（只这一次，弹密码框确认） |

新增窗口键时，`system/keyd/default.conf` 和 `config/niri/config.kdl` 两边都要改。

## niri：Cmd

| 按键 | 作用 |
|---|---|
| Cmd+Space | 启动器（类似 Spotlight） |
| Cmd+Shift+V | 剪贴板历史（选中后 Cmd+V / Caps+V 粘贴） |
| Cmd+Q | 关闭窗口 |
| Cmd+Ctrl+Q | 锁屏 |
| Cmd+Shift+S | 快捷设置（方向键 / hjkl 移动，Enter 执行，Esc 关闭，见 desktop.md） |
| Cmd+Shift+N | 通知中心（j k 选，Enter 打开，x 删除，d 勿扰，Esc 关闭） |
| Cmd+Tab / Cmd+` | 切换窗口 / 同一应用的窗口（按住 Cmd，←→ 选，Q 关掉选中的窗口；加 Shift 反向）。Alt+Tab 不占用 |
| Cmd+Shift+Q | 电源菜单：锁屏 / 睡眠 / 注销 / 重启 / 关机 / 重启进 macOS（←→ 选，Enter 确认，Esc 取消） |
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
