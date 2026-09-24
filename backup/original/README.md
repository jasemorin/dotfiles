# 原始配置备份（2026-09-24）

改成 GNOME 风格顶栏 + swaync 之前的版本（来自提交 3418c7e）。

恢复：
```bash
cd ~/dotfiles
cp backup/original/niri/config.kdl  config/niri/
cp backup/original/waybar/*         config/waybar/
pkill swaync; niri msg action spawn -- mako
pkill waybar; niri msg action spawn -- waybar
```
mako 的配置一直留在 config/mako/，这里也复制了一份。
