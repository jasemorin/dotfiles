# 重装 Asahi 并保留所有设置

配置在 GitHub（本仓库），个人文件在 iCloud。按顺序做即可。

## 1. 重装前：备份

```bash
cd ~/dotfiles
./scripts/snapshot.sh        # 导出软件包列表、dconf 设置，并打包个人文件
git status && git diff       # 仓库是公开的，确认没有私人信息
git add -A && git commit -m "重装前快照" && git push
```

`snapshot.sh` 做的事：

| 内容 | 去向 |
|---|---|
| dnf 手动装的包、flatpak、COPR 源 | `system/packages/` |
| 桌面设置（输入法、键盘重复、触控板等） | `system/dconf.ini`（已去掉定位坐标、窗口状态） |
| Documents / Pictures（含壁纸）/ Downloads 等、字体、Claude Code 设置与记忆 | `~/home-backup-日期.tar.gz` |

把 `~/home-backup-*.tar.gz` 传到 **icloud.com → 云盘**（Firefox 里上传即可）。

不需要备份的：

- Firefox：用 Firefox Sync 登录即可恢复书签、密码、扩展
- `~/.gitconfig`、`~/.bashrc`：前者见 setup-asahi.md 第 4 步，后者是 Fedora 默认
- `steam-arm64`（约 27G 游戏）：重新下载；想保留就拷到移动硬盘
- GitHub 登录：重新 `gh auth login`
- `~/.claude.json`：含登录凭据，不要放进仓库；重装后重新登录 Claude Code

## 2. 重装

1. 重启进 macOS（Linux 下 Caps+Shift+Esc）
2. 磁盘工具（或 `diskutil list`）删掉旧的 Asahi 分区：Linux 根分区、`/boot`、EFI 小分区。
   **不要动 macOS 的 APFS 容器和 Recovery**；删完把空间合并回来（或留着给新安装用）
3. 终端运行 `curl https://alx.sh | sh`，选 Fedora Asahi Remix

## 3. 重装后：一键恢复

1. 连上网，先从 icloud.com 把 `home-backup-*.tar.gz`（和 `wifi.tgz`，如果有）下载到 `~/Downloads`
2. 打开终端运行（开头输一次 sudo 密码）：

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jasemorin/dotfiles/asahi/restore.sh)
```

[`restore.sh`](../restore.sh) 会 clone 仓库到 `~/dotfiles`，然后依次：

- 启用 COPR，安装 `system/packages/` 里的全部软件包
- `install.sh` 链接 `~/.config`；链接个人脚本、bash 增强；写 swaync 的 dbus 服务；git 身份
- 部署 `/etc` 下的 keyd、tiny-dfr、zswap、mglru、tuned（即 setup-asahi.md 第 3 步）
- 系统的 xwayland-satellite 低于 0.8.3 时自己编译（见 [troubleshooting.md](troubleshooting.md)）
- `dconf load` 桌面设置
- 解压 `~/Downloads` 里的备份包（不覆盖已有文件），恢复 Wi-Fi，刷新字体缓存
- `gh auth login`

可以重复运行（已完成的会跳过）；先看会做什么用 `./restore.sh --dry-run`。

跑完后手动：Firefox 登录 Sync；注销后在登录界面齿轮里选 **niri**；跑 setup-asahi.md 末尾的检查清单。
