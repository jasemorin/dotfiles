---
name: run-dotfiles
description: Apply, check, and drive this dotfiles repo on the live Asahi/niri desktop. Use when asked to run or test a config change, validate niri/quickshell/waybar config, restart the top bar, take a screenshot of the desktop or bar, or check that restore.sh/install.sh still work.
---

这个仓库没有要构建的应用：「运行」= 把 `config/` 链接到 `~/.config`，niri 自动重载，然后通过 niri IPC 看结果。
agent 的入口是 `.claude/skills/run-dotfiles/driver.sh`：它自己找 niri socket（agent 的 shell 不是 niri 启动的，没有 `NIRI_SOCKET`），
能校验配置、重启顶栏、截图。截图和日志在 `/tmp/dotfiles-driver/`（可用 `OUT=` 改）。

所有路径相对仓库根目录 `~/dotfiles`。这是用户正在用的真实桌面：`bar` 会让顶栏闪一下，截图会连带用户屏幕上的内容。

## 前提

- 正在运行的 niri 会话（`ls /run/user/$(id -u)/niri.*.sock` 有结果）
- `python3-pillow`（截图等待/裁剪用）、`shellcheck`：Fedora 上已装
- 顶栏是 Quickshell ≥ 0.3（COPR `errornointernet/quickshell`）。**Fedora 官方仓库的 quickshell 是 0.3 之前的快照，没有 `BackgroundEffect`，配置会加载失败**
- agent **没有 sudo**（要密码，没有 tty）。凡是 `sudo` 的步骤让用户在终端自己跑

## 驱动（agent 走这条）

```bash
.claude/skills/run-dotfiles/driver.sh check          # 改完配置先跑这个，退出码 0 = 全部通过
.claude/skills/run-dotfiles/driver.sh bar            # 重启顶栏（quickshell，没有则 waybar）
.claude/skills/run-dotfiles/driver.sh ss after top   # -> /tmp/dotfiles-driver/after.png 和 after-top.png（只含顶栏）
.claude/skills/run-dotfiles/driver.sh state          # 输出缩放、图层（顶栏/壁纸/通知）、窗口
.claude/skills/run-dotfiles/driver.sh msg layers     # 任意 niri msg 子命令
```

| 命令 | 做什么 |
|---|---|
| `check` | `niri validate`；`bash -n` + shellcheck 所有脚本；`install.sh --dry-run` 全部「已就位」；`dconf.ini` 没有被锁定的键；真的启动一次 quickshell，日志里有 `Configuration Loaded` 且没有 `ERROR` |
| `bar` | 杀掉 waybar/quickshell 后重新启动，等到加载完成，日志在 `/tmp/dotfiles-driver/bar.log` |
| `ss [名字] [top]` | 整屏截图，会等文件写完；`top` 另存只含顶栏的一条 |
| `state` / `msg …` | 查看 niri 状态 / 直接转发 `niri msg` |

截图后**用 Read 打开 PNG 看一眼**，这是确认顶栏或窗口样式改对了的唯一办法。

### quickshell 没装、又没有 sudo 时

把 COPR 的 RPM 解压到任意目录，用 `QS_ROOT` 指过去（不装进系统，其余依赖 Fedora 上已有）：

```bash
D=/tmp/qs-rpm; mkdir -p $D/root && cd $D
dnf download --repofrompath=qs,https://download.copr.fedorainfracloud.org/results/errornointernet/quickshell/fedora-44-aarch64/ \
  --setopt=qs.gpgcheck=0 --repo=qs --repo=fedora --repo=updates quickshell cpptrace libdwarf jemalloc
for r in *.aarch64.rpm; do rpm2cpio "$r" | (cd root && cpio -idm 2>/dev/null); done
cd ~/dotfiles && QS_ROOT=/tmp/qs-rpm/root .claude/skills/run-dotfiles/driver.sh check
```

正式安装（用户自己跑；需要 sudo，agent 没法验证）：`sudo dnf copr enable -y errornointernet/quickshell && sudo dnf install -y quickshell`

## 改配置的流程

- **niri**（`config/niri/config.kdl`）：保存即自动重载，不用重启。先 `driver.sh check` 再看效果。
- **quickshell**（`config/quickshell/*.qml`）：运行中的实例检测到文件变化会自己重载（日志出现 `Reloading configuration...`），重载失败或改了启动参数时用 `driver.sh bar`。
- **waybar**（备用顶栏，没装 quickshell 时 niri 才会启动它）：不会自动重载，用 `driver.sh bar`。
- **新增 `config/<工具>/`**：`./install.sh` 会自动链接，不用改脚本。
- **重装恢复**：`./restore.sh --dry-run` 看会做什么；真正运行要 sudo，让用户跑。

## 用户自己怎么跑

装好 quickshell 后，注销再登录 niri，或在 niri 里的终端运行 `pkill quickshell; niri msg action spawn -- qs`（写这份文档时 quickshell 还没正式安装，这条没验证过；niri 的启动项是 `command -v qs && exec qs || exec waybar`）。

## 坑

- **niri 只能模糊整个图层矩形。** waybar 的「分开的胶囊」配 `layer-rule { background-effect { blur true } }`，胶囊之间会出现一条磨砂横带。只模糊胶囊需要客户端通过 `ext-background-effect` 申请模糊区域，waybar 0.15 不支持，所以换成了 Quickshell（`BackgroundEffect.blurRegion` + `Region { item; radius }`）。
- **waybar 设 `"width": 1` 不会缩到内容宽度**，图层照样占满整个屏幕宽度，所以「每个胶囊一个 waybar 实例」行不通。
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
