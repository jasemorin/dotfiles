#!/bin/sh
# 关闭 swaync 面板后运行命令（设置、锁屏按钮用）
swaync-client -cp
exec "$@"
