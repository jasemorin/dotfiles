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

## 3. 重装后：恢复

```bash
# GitHub 登录并拉仓库
sudo dnf install gh git && gh auth login && gh auth setup-git
git clone https://github.com/jasemorin/dotfiles.git ~/dotfiles
cd ~/dotfiles && git checkout asahi

# 软件包（先加 COPR 源）
xargs -rn1 sudo dnf copr enable -y < system/packages/copr.txt
sudo dnf install --skip-unavailable $(cat system/packages/dnf.txt)
xargs -rn1 flatpak install -y flathub < system/packages/flatpak.txt

# 配置链接和桌面设置
./install.sh --dry-run && ./install.sh
dconf load / < system/dconf.ini
```

然后按 [setup-asahi.md](setup-asahi.md) 第 3、4 步部署系统级配置（keyd、tiny-dfr、zswap、
mglru、tuned、bash、swaync 的 dbus 服务），以及：

```bash
# 个人脚本
mkdir -p ~/.local/bin
ln -s ~/dotfiles/scripts/steam-arm64.sh ~/.local/bin/steam-arm64
ln -s ~/dotfiles/scripts/reboot-macos.sh ~/.local/bin/reboot-macos
```

- 自编译的 xwayland-satellite 0.8.3：见 [troubleshooting.md](troubleshooting.md)（Fedora 更新到 0.8.3 后可以不用）
- 从 iCloud 下载备份包，`tar xzf home-backup-*.tar.gz -C ~` 解压，再 `fc-cache -f`
- Firefox 登录 Sync；Firefox 内存设置见 [memory.md](memory.md)
- 最后跑 setup-asahi.md 末尾的检查清单
