# 踩过的坑和解决办法

## Caps 变回普通大小写锁定

**原因**：keyd 崩溃退出了。`sudo keyd reload` 时如果还有键没松开（比如按回车运行这条命令），keyd 2.6 可能段错误。

**解决**：
```bash
sudo systemctl restart keyd
journalctl -u keyd -b | tail      # 看是否有 SEGV / core-dump
```
预防：部署新配置用 `sudo systemctl restart keyd`；并加上崩溃自动重启（见 setup-asahi.md 第 3 步）。

## 按住 fn 时 Touch Bar 不切换到 F1-F12

**原因**：keyd 独占物理键盘后，通过自己的虚拟键盘转发按键；而它的虚拟键盘只支持到键码 372，
fn（KEY_FN=464）发不出去。Touch Bar 程序 tiny-dfr 只认 fn 来切换层，所以收不到。重启 tiny-dfr 没用。
（检查方法：`/proc/bus/input/devices` 里 `keyd virtual keyboard` 的 KEY 位图没有 464。）

**解决**：
- Touch Bar 默认显示媒体键（`system/tiny-dfr/config.toml` 里 `MediaLayerDefault = true`，同 macOS）
- F1-F12 由 keyd 的 fn 层提供：fn+数字行（keyd 能**读到** fn，只是发不出去）

## 每次登录 niri 都弹一条失败通知

**原因**：Fedora 的 imsettings（输入法启动器）通过 `/etc/xdg/autostart/imsettings-start.desktop` 自动启动；
没配输入法时它在 niri 下子进程报错退出（`~/.cache/imsettings/log` 里 `Child process exited with code 1`），然后发通知。

**解决**：`config/autostart/imsettings-start.desktop` 覆盖系统那份，加 `NotShowIn=niri;`（GNOME 下照常）。
以后如果要装中文输入法（如 fcitx5），记得去掉这个覆盖。

## kitty 下拉终端（Caps+Shift+Enter）一打开就崩溃

**原因**：kitty 0.47 的 bug。`kitty.conf` 里的 `hide_window_decorations titlebar-only` 被下拉终端继承，
它是 layer-shell 窗口没有标题栏，kitty 在 `glfwWaylandSetTitlebarHidden` 里空指针崩溃。

**解决**：`config/kitty/quick-access-terminal.conf` 里加 `kitty_override hide_window_decorations=no`（已加）。

另外 `hide_on_focus_loss yes` 在 niri 下会导致再按一次收不起来，暂不启用。

## kitty 聚焦时背景变成不透明

**原因**：kitty 没让 niri 画边框，niri 就把 focus ring 画成实心矩形垫在窗口后面，只有聚焦的窗口有。

**解决**：niri 的 kitty 窗口规则里加 `draw-border-with-background false`（已加）。

## kitty 背景模糊看起来没效果

niri 默认只模糊背后的**壁纸**（xray），不模糊背后的其他窗口。纯色壁纸模糊了也看不出来；
花哨壁纸需要更强的模糊（`blur { passes 4; offset 6.0; }`，已设置）。

## 壁纸不显示

swaybg 读不了 AVIF（有些图片扩展名是 .jpg 实际是 AVIF，用 `file 图片` 检查）。
转换：`ffmpeg -i 原图 -q:v 2 新图.jpg`，或装 `avif-pixbuf-loader`。

## 需要管理员权限的图形操作没反应

**原因**：niri 下没有 polkit 认证代理（GNOME 自带，niri 没有）。

**解决**：装 `mate-polkit`，niri 开机启动 `/usr/libexec/polkit-mate-authentication-agent-1`（已配置）。
测试：`pkexec true` 应弹出密码框。

## 内存不够、交换区占满

见 [memory.md](memory.md)。

## nvim：试过 LazyVim 后想回到自己的配置

配置在 git 里，直接恢复：
```bash
cd ~/dotfiles && git restore --source=HEAD --staged --worktree config/nvim
```
插件数据：LazyVim 会用自己的 `~/.local/share/nvim` 等目录，切换前先把原目录改名备份，回来时换回去。

## 访问 macOS 那边的文件

读不了。Apple Silicon 上 macOS 数据卷由安全芯片加密，Linux 解不开；macOS 也读不了 Linux 的 btrfs。
两边传文件用网盘（iCloud 网页版）、U 盘（exFAT），或临时借用 FAT32 的 EFI 分区（只放新文件夹，用完删掉）。
