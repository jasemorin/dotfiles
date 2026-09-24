# 在 Asahi 上玩游戏（MacBook Pro M2，8 GB）

## 先有个预期

- Asahi 官方的游戏方案可以跑 x86 的 Steam 游戏（包括 Windows 游戏），但官方建议**至少 16 GB 内存**。
  这台只有 8 GB，大型 3A 游戏基本不现实；**独立游戏、老游戏、2D 游戏**比较合适。
- 新的 3A 游戏即使在 16 GB 机器上也还到不了 60 帧；部分 DX12 游戏因为显卡驱动还缺功能（sparse texturing）跑不了。
- 需要内核级反作弊的网游（Valorant 等）在任何 Linux 上都玩不了。

## 1. Steam（x86 / Windows 游戏）

原理：Steam 和游戏跑在一个小虚拟机里（muvm，用 4K 页内核；主系统是 16K 页），
FEX 把 x86 指令翻译成 ARM，Proton（Wine + DXVK / vkd3d-proton）把 Windows 和 DirectX 转成 Linux 和 Vulkan。
显卡驱动 Honeykrisp 是通过一致性认证的 Vulkan 1.3。

```bash
sudo dnf upgrade --refresh && sudo reboot
sudo dnf install steam
```

之后从启动器（Cmd+Space）打开 Steam。Windows 游戏在「属性 → 兼容性」里勾选用 Proton 运行。

- 如果 GNOME 下报 `Failed to mount filesystems`：`sudo hostnamectl hostname 你的主机名`
- niri 下 Steam 走 X11，由 xwayland-satellite 提供（已安装，niri 会自动启动）

**ARM 原生 Steam 客户端（实验，已隔离安装）**：Valve 为 Steam Frame 做的 arm64 Linux 客户端，
只在 public beta 通道，没有正式支持。用 `scripts/steam-arm64.sh`（改编自 UbuntuAsahi/steam-arm64）安装：

```bash
steam-arm64 install     # 下载客户端和 GE-Proton arm64（约 730 MB）
steam-arm64             # 运行；第一次会装 Steam Runtime 4.0，需要登录
steam-arm64 uninstall   # 整个删掉
```

- **隔离安装**：数据全在 `~/.local/share/steam-arm64`（单独的家目录），不碰现有 x86 Steam 的 `~/.local/share/Steam`
- 启动器里叫「Steam (arm64)」；和 x86 Steam **不能同时开**，先从菜单退出另一个
- 游戏大多仍是 x86，照样靠 muvm + FEX；省的主要是客户端界面（内嵌浏览器不用再经 x86 翻译）
- beta 通道，随时可能坏；坏了就 `steam-arm64 uninstall`，回到 `steam`
- 实测内存：ARM 版约 **1.4 GB**，x86 版约 3.9 GB
- 已知坑（2026-09 这版）：包里的 `libSDL3.so` 误打成 x86，且需要 SDL 开发分支才有的 `SDL_TryLockJoysticks`。
  解决：`sudo dnf builddep SDL3 && sudo dnf install cmake ninja-build gcc-c++`，
  在 `~/.local/share/steam-arm64/src` 里用 cmake 编译 SDL main，把 `libSDL3.so.0.*` 拷进 `steamrtarm64/` 并让 `libSDL3.so`、`libSDL3.so.0` 指向它
  （原 x86 文件留作 `libSDL3.so.x86`）。Valve 更新客户端后可能被覆盖，需要重做

官方报告能玩的例子：Hollow Knight（满速）、Portal 2、Control、The Witcher 3、Fallout 4、Ghostrunner、Cyberpunk 2077（后几个在 8 GB 上很吃力）。

## 2. 原生 ARM 游戏（最省内存，效果最好）

不需要 x86 翻译，直接用 dnf 或 Flathub 装：

- `sudo dnf install supertuxkart`（赛车）、`luanti`（类 Minecraft）、`0ad`（即时战略）
- Minecraft Java 版：用 Prism Launcher（Flathub），Java 原生支持 ARM
- 模拟器：RetroArch、Dolphin（GameCube / Wii）、PPSSPP 都有 ARM 版本，效果很好

## 3. 云游戏

GeForce NOW、Xbox Cloud Gaming 在浏览器里玩，游戏在服务器上跑，不吃本机内存和显卡，只要网络好。
这类服务对 Chromium 支持最好（`sudo dnf install chromium`）。

## Steam 本身就很吃内存

实测：只开 Steam 客户端（不开游戏），muvm 虚拟机就占主机约 **3.6–3.9 GB**。
Steam 的界面是内嵌浏览器（CEF），跑在 x86 翻译层上特别重；内存不够时虚拟机里的进程被结束，
表现为 **Steam 窗口频繁闪退**（`~/.local/share/Steam/logs/webhelper.txt` 里渲染进程不停重启）。
主机日志看不到，因为是虚拟机内部的系统结束的。

省内存的 Steam 设置：
- 设置 → 界面：关「在网页视图中启用 GPU 加速渲染」（在 Asahi 上也更稳）、关动画头像和动画、关「启动时显示 Steam 新闻」
- 设置 → 库：开「低性能模式」「低带宽模式」
- 设置 → 游戏中：关 Steam 覆盖层
- 设置 → 好友：关启动时自动登录好友
- 平时用「视图 → 小模式」
- 不开主界面直接启动游戏：`steam -silent steam://rungameid/游戏ID`（ID 在商店网址里，如 Hollow Knight 是 367520）
- **不玩的时候退出 Steam**（菜单 Steam → 退出，关窗口只是缩到后台）

## 玩之前（8 GB 内存必做）

- 关掉 Firefox 和不用的 Claude Code 会话，这两个加起来能占 4 GB 以上（见 [memory.md](memory.md)）
- 查看可用内存：`free -h` 的 available 列
- 插上电源；游戏时切到 gaming 模式（性能模式 + 保留 swappiness 60，见 `system/tuned/gaming`）：
  `sudo tuned-adm profile gaming`，玩完**切回** `sudo tuned-adm profile balanced`。
  不要用 `throughput-performance`：它把 swappiness 设成 10，8 GB 上更容易卡、Steam 更容易闪退

## niri 下的键位注意

- 全屏：Caps+Shift+M
- 游戏里要用 Ctrl：按住 Caps 或物理 Control 都行；但 Caps+h/j/k/l、Caps+数字等会被 niri 拿走
- 如果游戏需要这些组合键：Caps+Esc 暂停 niri 快捷键，玩完再按一次恢复
- 手柄：蓝牙手柄（Xbox、PS）可以直接配对（点顶栏蓝牙）
