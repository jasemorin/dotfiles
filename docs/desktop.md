# 桌面功能一览（niri + Quickshell）

> 只在 Linux 上有。键位见 [keybindings.md](keybindings.md)；改配置、重启顶栏、截图验证的流程见
> `.claude/skills/run-dotfiles/SKILL.md`。界面统一用 Catppuccin Mocha：强调色 lavender `#b4befe`（和 niri 的 focus ring 同色），
> 半透明深色底 + 背后模糊，字体 Adwaita Sans，图标来自 Symbols Nerd Font。

## 顶栏

分开的胶囊，每个胶囊背后单独模糊（`config/quickshell/Bar.qml`）。

| 胶囊 | 显示 | 操作 |
|---|---|---|
| 工作区（左） | 圆点，当前工作区是长条 | 点圆点切换；滚轮切上 / 下一个 |
| 窗口标题 | 当前窗口标题，超过 60 字截断 | 悬停看完整标题 |
| 时钟（中） | 日期时间；右边小圆点 = 有未读通知，󰂛 = 勿扰，󰅶 = 保持唤醒 | 点击打开通知中心 |
| 媒体 | 正在播放的曲目 | 左键播放 / 暂停，右键下一首，中键上一首 |
| 内存 | 已用百分比 | 悬停看 GiB |
| 网速 | ↑ 上传 ↓ 下载 | — |
| 托盘 | 应用托盘图标（fcitx5、Steam 等） | 左键激活，右键菜单，中键次要动作 |
| 系统图标（右） | 蓝牙、网络、音量、电池 | 点击打开快捷设置；滚轮调音量；音量图标右键静音。电池 ≤20% 变黄，≤10% 变红 |

## 快捷设置（点右上角系统图标）

`config/quickshell/QuickSettings.qml`。Esc 或点面板外面关闭。

- 顶部：电量和剩余时间；右边 󰌾 锁屏、󰐥 电源菜单
- 方块：Wi-Fi、蓝牙、勿扰、通知（打开通知中心）、**保持唤醒**、**夜间模式**
- 滑块：音量（点图标静音）、屏幕亮度
- 电源模式：节能 / 平衡 / 性能（tuned-ppd）；`gaming` 这类自定义模式不高亮按钮，下面单独写出名字
- Wi-Fi、蓝牙方块右边的 󰅂 展开列表：附近的网络（展开时扫描；已保存 / 开放的直接连，加密的新网络在那一行下面输密码）、
  蓝牙设备（已连接的在前，带电量；下面是附近的新设备，选中即配对并连接）；「网络设置…」打开 `nm-connection-editor`

**键盘操作**（面板打开时独占键盘）：

| 按键 | 作用 |
|---|---|
| 方向键 / h j k l | 移动焦点框（第一次按只把焦点框显示出来） |
| Tab / Shift+Tab | 按顺序走 |
| Enter / 空格 | 执行：开关方块、展开列表（焦点跳到第一项）、连接网络 / 设备 |
| ← → （焦点在滑块上） | 音量 / 亮度 ±5% |
| Esc | 先收起展开的列表，再按关闭面板；密码框里 Esc 取消输入 |

## 通知

Quickshell 自己当通知服务（`Notifs.qml`），取代 swaync。

- **弹窗**：顶栏下方右侧往下叠；鼠标悬停时暂停倒计时；点击执行默认动作，× 删除，往旁边滑收起
- **通知中心**：点时钟打开；上面月历，下面历史、勿扰开关、全部清除；往旁边滑删除
- **勿扰**：只有紧急通知还会弹出
- **低电量提醒**（`BatteryWarn.qml`）：放电时降到 20% 发普通通知，10%、5% 发紧急通知（不自动消失，勿扰也弹）；
  插上电源后重置。拔电时已经低于 20% 的话只提醒一次当前档位

## 电源菜单（Cmd+Shift+Q）

`config/quickshell/SessionMenu.qml`。全屏模糊遮罩（只透出模糊的壁纸，和锁屏背景一个样子）+ 一排大按钮：

| 按钮 | 执行 |
|---|---|
| 锁屏 | `swaylock -f` |
| 睡眠 | `systemctl suspend`（swayidle 在睡眠前先锁屏） |
| 注销 | `niri msg action quit --skip-confirmation` |
| 重启 | `systemctl reboot` |
| 关机 | `systemctl poweroff` |
| macOS | `~/.local/bin/reboot-macos`：只下一次重启进 macOS，会弹密码框 |

←→ / h l / Tab 选择，Enter 或空格确认，Esc 或点空白处取消，鼠标悬停也会移动选中项。
**没有单键直达**：误按一个键就关机太危险。也可以从快捷设置右上角的 󰐥 打开。

## 锁屏、闲置、保持唤醒

- swayidle（niri 启动）：闲置 5 分钟锁屏，再过 30 秒关屏，睡眠前锁屏
- 锁屏背景是壁纸的模糊暗化版 `~/.cache/swaylock/wallpaper.png`：niri 启动时用 `magick` 生成（约 1 秒），
  壁纸文件比缓存新时才重新生成。缓存不存在时 swaylock 照样锁屏，只是用纯色 `#1e1e2e` 背景
- **保持唤醒**（快捷设置方块）：顶栏挂一个 Wayland idle inhibitor，开着时 swayidle 不锁屏也不关屏，时钟旁显示 󰅶。
  只管「闲置」：合盖照样睡眠（logind 管）。重启 quickshell 后回到关闭

## 夜间模式

快捷设置方块，开着时 quickshell 带一个 `wlsunset -t 4000 -T 4001` 子进程：色温固定 4000K，不随日出日落变化；
关掉开关或 quickshell 退出时屏幕色温恢复。需要先装：`sudo dnf install wlsunset`（没装时方块显示「未安装」）。
重启 quickshell 后回到关闭。

## 音量 / 亮度提示

按音量键、亮度键（Touch Bar）时屏幕下方弹出一个模糊胶囊，1.5 秒后消失（`Osd.qml`）。

## 壁纸和概览

- swaybg 显示 `~/Pictures/wallpaper/uluru1.JPEG`（没有就用纯色）
- 工作区背景透明、壁纸放在 niri 的 backdrop（`layer-rule` 里的 `place-within-backdrop`）：
  切工作区时壁纸不跟着滑走，概览（Caps+`）里背后也是壁纸而不是灰底
- 窗口和面板的模糊默认是 xray（透出的是模糊的壁纸，不是后面的窗口）；快捷设置、通知这类盖在窗口上的面板改成模糊背后的窗口

## 从脚本或快捷键调用（`qs ipc call`）

| 命令 | 作用 |
|---|---|
| `qs ipc call bar quickSettings` | 打开 / 关闭快捷设置 |
| `qs ipc call bar notifications` | 打开 / 关闭通知中心 |
| `qs ipc call session toggle` | 打开 / 关闭电源菜单（Cmd+Shift+Q 就是这个） |

在 niri 里绑键：`Mod+X { spawn "qs" "ipc" "call" "bar" "quickSettings"; }`。
