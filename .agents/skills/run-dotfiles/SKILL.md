---
name: run-dotfiles
description: Apply, check, and drive this dotfiles repo on the live Asahi/niri desktop. Use when asked to run or test a config change, validate niri/quickshell/waybar config, restart the top bar, take a screenshot of the desktop or bar, or check that restore.sh/install.sh still work.
---

这个仓库没有要构建的应用：「运行」= 把 `config/` 链接到 `~/.config`，niri 自动重载，然后通过 niri IPC 看结果。
agent 的入口是 `.Codex/skills/run-dotfiles/driver.sh`：它自己找 niri socket（agent 的 shell 不是 niri 启动的，没有 `NIRI_SOCKET`），
能校验配置、重启顶栏、截图。截图和日志在 `/tmp/dotfiles-driver/`（可用 `OUT=` 改）。

所有路径相对仓库根目录 `~/dotfiles`。这是用户正在用的真实桌面：`bar` 会让顶栏闪一下，截图会连带用户屏幕上的内容。

## 前提

- 正在运行的 niri 会话（`ls /run/user/$(id -u)/niri.*.sock` 有结果）
- `python3-pillow`（截图等待/裁剪用）、`shellcheck`：Fedora 上已装
- 顶栏是 Quickshell ≥ 0.3（COPR `errornointernet/quickshell`）。**Fedora 官方仓库的 quickshell 是 0.3 之前的快照，没有 `BackgroundEffect`，配置会加载失败**
- agent **没有 sudo**（要密码，没有 tty）。凡是 `sudo` 的步骤让用户在终端自己跑

## 驱动（agent 走这条）

```bash
.Codex/skills/run-dotfiles/driver.sh check          # 改完配置先跑这个，退出码 0 = 全部通过
.Codex/skills/run-dotfiles/driver.sh bar            # 重启顶栏（quickshell，没有则 waybar）
.Codex/skills/run-dotfiles/driver.sh ss after top   # -> /tmp/dotfiles-driver/after.png 和 after-top.png（只含顶栏）
.Codex/skills/run-dotfiles/driver.sh state          # 输出缩放、图层（顶栏/壁纸/通知）、窗口
.Codex/skills/run-dotfiles/driver.sh msg layers     # 任意 niri msg 子命令
.Codex/skills/run-dotfiles/driver.sh ipc bar quickSettings   # 打开/关闭快捷设置面板（再调一次关闭）
```

| 命令 | 做什么 |
|---|---|
| `check` | `niri validate`；`bash -n` + shellcheck 所有脚本；`install.sh --dry-run` 全部「已就位」；`dconf.ini` 没有被锁定的键；真的启动一次 quickshell，日志里有 `Configuration Loaded` 且没有 `ERROR` |
| `bar` | 杀掉 waybar/quickshell，通过 `niri msg action spawn` 重新启动（成为 niri 的子进程，agent 的 shell 退出后还在），等 niri 里出现 `quickshell-bar` 图层才算成功，日志在 `/tmp/dotfiles-driver/bar.log` |
| `ss [名字] [top]` | 整屏截图，会等文件写完；`top` 另存只含顶栏的一条 |
| `state` / `msg …` | 查看 niri 状态 / 直接转发 `niri msg` |
| `ipc <目标> <函数>` | 调用 quickshell 的 `IpcHandler`（`qs ipc call`，用修正过的 `WAYLAND_DISPLAY`） |

截图后**用 Read 打开 PNG 看一眼**，这是确认顶栏或窗口样式改对了的唯一办法。

### quickshell 没装、又没有 sudo 时

把 COPR 的 RPM 解压到任意目录，用 `QS_ROOT` 指过去（不装进系统，其余依赖 Fedora 上已有）：

```bash
D=/tmp/qs-rpm; mkdir -p $D/root && cd $D
dnf download --repofrompath=qs,https://download.copr.fedorainfracloud.org/results/errornointernet/quickshell/fedora-44-aarch64/ \
  --setopt=qs.gpgcheck=0 --repo=qs --repo=fedora --repo=updates quickshell cpptrace libdwarf jemalloc
for r in *.aarch64.rpm; do rpm2cpio "$r" | (cd root && cpio -idm 2>/dev/null); done
cd ~/dotfiles && QS_ROOT=/tmp/qs-rpm/root .Codex/skills/run-dotfiles/driver.sh check
```

正式安装（需要 sudo，让用户跑）：`sudo dnf copr enable -y errornointernet/quickshell && sudo dnf install -y quickshell`

## 改配置的流程

- **niri**（`config/niri/config.kdl`）：保存即自动重载，不用重启。先 `driver.sh check` 再看效果。
- **quickshell**（`config/quickshell/*.qml`）：改完用 `driver.sh bar` 重启。通过 `~/.config/quickshell` 这个符号链接启动的实例**不会**自动重载（只有 `-p` 指向真实目录时才会）。
  文件分工：`shell.qml` 入口；`Bar.qml` 顶栏；`QuickSettings.qml` 快捷设置面板；`Osd.qml` 音量/亮度提示；`NotificationPopups.qml` 通知弹窗、`NotificationCenter.qml` 通知中心（月历 + 历史）、`NotificationCard.qml` 一条通知（可侧滑）；`Niri`/`SysInfo`/`Brightness`/`Notifs.qml` 状态单例；`Pill`/`Label`/`SysIcon`/`Tooltip.qml` 组件。
  **重启会丢掉通知历史**（`keepOnReload` 只管重载），测通知前别在中途重启。
- **waybar**（备用顶栏，没装 quickshell 时 niri 才会启动它）：不会自动重载，用 `driver.sh bar`。
- **新增 `config/<工具>/`**：`./install.sh` 会自动链接，不用改脚本。
- **重装恢复**：`./restore.sh --dry-run` 看会做什么；真正运行要 sudo，让用户跑。

### 看不到的东西怎么验证

- **悬停提示、点击**：niri 没有移动指针的 IPC。把组件复制到临时目录，写一个 `WlrLayer.Overlay` 的测试 `shell.qml`，把 `Tooltip.qml` 的 `visible: shown && text !== ""` 改成 `visible: text !== ""` 强制显示，用 `niri msg action spawn -- sh -c "exec qs -p <临时目录>"` 起一个单独的实例截图。overlay 层在全屏窗口之上，用户开着全屏 Firefox 也能截到。
- **快捷设置面板**：`driver.sh ipc bar quickSettings` 打开，截图，再调一次关闭（它打开时独占键盘，别让它一直开着）。通知中心同理：`driver.sh ipc bar notifications`。
- **通知**：`notify-send -a 应用 -i 图标 "标题" "正文"`；动作按钮用 `-A "id=文字" --wait`（放后台跑）；紧急用 `-u critical`。确认通知服务是 quickshell：`busctl --user status org.freedesktop.Notifications | grep ^Comm`。注意 **niri 每次截图都会发一条「Screenshot captured」通知**（transient，弹窗过后不进历史）。
- **只能靠逻辑验证的交互**（侧滑等）：临时实例里用假的 `QtObject` 当通知，直接调 `offset` / `finishSwipe()`，用 `console.warn` 输出结果。测试窗口别放在屏幕中间：用户的鼠标可能正好在上面，真实输入会干扰结果。
- **音量/亮度提示**：`wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+ -l 1.0` 后截屏幕下方，再 `0.05-` 调回；亮度先记下 `brightnessctl --class=backlight get`，`set +1%` 后截图，再 `set <原值>`。
- **媒体胶囊**：需要一个 MPRIS 播放器。没有的话用 Python + `gi.repository.Gio` 注册 `org.mpris.MediaPlayer2.<名字>`，实现 `PlaybackStatus`/`Metadata` 属性和 `PlayPause`/`Next` 方法即可，用 `playerctl -l` 确认。
- 杀测试进程别用 `pkill -f <路径>`：模式会匹配到执行它的那条 bash 命令，把命令自己杀掉（退出码 144）。用 `pgrep -f` 找到进程号再 `kill`。

## 用户自己怎么跑

注销再登录 niri，或运行 `pkill -x qs; niri msg action spawn -- qs`。注意用 `qs` 启动时进程名是 `qs`，`pkill quickshell` 杀不到它。niri 的启动项是 `command -v qs && exec qs || exec waybar`。

## 坑

- **niri 只能模糊整个图层矩形。** waybar 的「分开的胶囊」配 `layer-rule { background-effect { blur true } }`，胶囊之间会出现一条磨砂横带。只模糊胶囊需要客户端通过 `ext-background-effect` 申请模糊区域，waybar 0.15 不支持，所以换成了 Quickshell（`BackgroundEffect.blurRegion` + `Region { item; radius }`）。
- **waybar 设 `"width": 1` 不会缩到内容宽度**，图层照样占满整个屏幕宽度，所以「每个胶囊一个 waybar 实例」行不通。
- **agent 的 shell 里 `WAYLAND_DISPLAY` 可能是过期的值**（遇到过 `wayland-0`，而 niri 用的是 `wayland-1`）。Qt 连不上就退回 xcb，顶栏画不出来，**日志却照样写 `Configuration Loaded`**。driver 发现 socket 不存在时会从 `NIRI_SOCKET` 重新推断，并且以 `niri msg layers` 里出现 `quickshell-bar` 为准判断是否成功。
- **带 `grabFocus` 的 `PopupWindow` 必须由真实点击打开**，从 IPC / 快捷键打开会被 niri 立刻撤掉。所以快捷设置面板用的是 overlay 层的 `PanelWindow`，下面垫一层全屏透明窗口，点到外面就关闭。
- **`qs ipc call` 报 `No running instances`**：它只找同一个 `WAYLAND_DISPLAY` 上、同一个配置路径的实例。用 `driver.sh ipc`；实例也要和 niri 启动项一样不带 `-p`（用 `~/.config/quickshell`）。
- **niri 下 Qt 没有图标主题**（GNOME 下会自动用 Adwaita），fcitx 的 `input-keyboard-symbolic` 加载失败，染白后变成白方块。`shell.qml` 开头的 `//@ pragma IconTheme Adwaita` 解决；托盘右键菜单还需要 `//@ pragma UseQApplication`。
- **模糊默认是 xray**（只模糊壁纸）。盖在窗口上的面板和提示会透出壁纸颜色（乌鲁鲁的红土色），niri 的 `layer-rule` 对 `quickshell-(osd|quicksettings)` 设了 `xray false`。
- **`tuned-adm profile balanced` 会让 PowerProfiles 接口报 `unknown`**（tuned-ppd 在用电池时期望的是 `balanced-battery`），Quickshell 就停在默认值，误显示成「平衡」。面板按 `tuned-adm active` 显示；切换用 PowerProfiles（不用 sudo：`busctl --system set-property net.hadess.PowerProfiles /net/hadess/PowerProfiles net.hadess.PowerProfiles ActiveProfile s balanced`）。
- **QML 里的 `console.log` 看不到**：日志默认不输出 debug 级别，`qs log -r "*.debug=true"` 也读不出来。调试用 `console.warn`，它会出现在 `/tmp/dotfiles-driver/bar.log`。
- **通知服务只能有一个**：swaync 占着 `org.freedesktop.Notifications` 时 quickshell 注册不上（日志 `Could not register notification server`，对方退出后会自动重试）。`~/.local/share/dbus-1/services/org.freedesktop.Notifications.service` 的自动启动已改成只在没装 quickshell 时启动 swaync，否则 quickshell 重启的间隙会被 swaync 抢走。
- **磁盘写满时文件会被截成 0 字节**（遇到过：Steam 下载 CS2 写满了 90 GB）。写文件报 `No space left on device` 后，先检查 `wc -c` 再继续，没提交的新文件要从别处恢复。
- **niri 的截图是异步的**：`niri msg action screenshot-screen --path` 立刻返回，文件稍后才写完。driver 会轮询直到 PNG 能打开。
- **缩放 1.67**：截图是物理像素 2560×1600，niri 的窗口尺寸是逻辑像素 1536×960。裁剪用物理坐标。
- **窗口方角**：新 Firefox 配置文件启动时请求最大化，niri 会贴边最大化，这种窗口不画圆角。靠全局 `open-maximized-to-edges false` 解决。
- **Qt 里的 symbolic 托盘图标是深色的**（GTK 会自动染成文字颜色，Qt 不会），用 `MultiEffect { brightness: 1.0 }` 染白，只对名字带 `symbolic` 的图标生效。
- **电池百分比**：waybar 按能量自己算（energy/energy_full），比 UPower 和 `/sys/class/power_supply/macsmc-battery/capacity` 低约 3%。以系统报告的为准。
- **`set -o pipefail` 下 `fc-list | grep -q …` 会误判为不存在**（grep 提前退出，fc-list 收到 SIGPIPE）。用 `[[ -n "$(fc-list "字体名")" ]]`。
- **`system/packages/dnf.txt` 必须用 `sort -u` 排序**（和 `scripts/snapshot.sh` 一致），用 `sort -f` 会打乱十几行。

## 排错

- **`dconf load` 报 `The operation attempted to modify one or more non-writable keys`**：`[org/gnome/login-screen]` 被 Fedora 锁定，整个导入都会失败，`restore.sh` 因为 `set -e` 停在这一步。删掉这一段；`snapshot.sh` 已经会过滤它。
- **`libdwarf.so.2: cannot open shared object file`**（用 `QS_ROOT` 时）：`LD_LIBRARY_PATH` 没设上。在 `$(…)` 子 shell 里 export 的变量传不回来，driver 里是在顶层设的。
- **`NIRI_SOCKET is not set, are you running this within niri?`**：agent 的 shell 不在 niri 里。用 `driver.sh msg …`，或者 `export NIRI_SOCKET=$(ls /run/user/$(id -u)/niri.*.sock)`。
- **顶栏图标显示成方框**：缺 Symbols Nerd Font。`restore.sh` 会自动下载，手动装见 `docs/setup-asahi.md`。
- **quickshell 日志里的 `Failed to register with host portal … already associated with an application ID`**：无害，可以忽略。
- **`Error demarshalling property update … Invalid PowerProfile: unknown`**：见上面 tuned 那条；用 tuned-adm 切到 gaming 时也会出现，无害。
