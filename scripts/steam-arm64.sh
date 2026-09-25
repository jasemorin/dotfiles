#!/usr/bin/env bash
# ARM64 原生 Steam 客户端（Valve public beta 通道），仅 Asahi Linux
#
# 改编自 UbuntuAsahi/steam-arm64（原脚本只适用于 Ubuntu，而且装进 ~/.local/share/Steam，
# 会和 Fedora 的 x86 Steam 混在一起）。这里改成隔离安装：ARM Steam 用单独的「家目录」
# ~/.local/share/steam-arm64，它的文件、~/.steam 链接、配置都在里面，不碰现有 Steam。
#
# 用法：
#   steam-arm64 install   下载并安装（不开界面）
#   steam-arm64           运行（第一次会先装 Steam Runtime 4.0，需要登录）
#   steam-arm64 uninstall 删除整个隔离目录和菜单项
#
# 注意：和 x86 Steam 不能同时运行，先退出另一个。游戏大多仍是 x86，照样靠 muvm + FEX。
set -euo pipefail

ARMHOME="${STEAM_ARM64_HOME:-$HOME/.local/share/steam-arm64}"
STEAMROOT="$ARMHOME/.local/share/Steam"
DL="$ARMHOME/downloads"
PROTON=GE-Proton11-5-aarch64
PROTON_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton11-5/$PROTON.tar.gz"
DESKTOP="$HOME/.local/share/applications/steam-arm64.desktop"
# 虚拟机内存上限（MiB）。muvm 默认给主机内存的 80%（约 5.9 GB）：虚拟机里读写过的文件（比如下载游戏）
# 会留在它自己的页缓存里，在主机上就是普通的程序内存，只能被挤进交换空间、不会还回来。
# 2026-09-25 下 CS2 时虚拟机涨到 4.2 GB（3.2 GB 在交换里），交换被撑满，其他程序接连被 OOM 结束。
# ARM Steam 客户端约 1.4 GB，3.5 GB 够玩小游戏；大游戏临时调高：STEAM_ARM64_MEM=5120 steam-arm64
MEM="${STEAM_ARM64_MEM:-3584}"

install_client() {
    mkdir -p "$DL" "$STEAMROOT"

    if ! [ -e "$STEAMROOT/steamrtarm64" ]; then
        local zip
        zip=$(curl -fsS https://client-update.steamstatic.com/steam_client_publicbeta_linuxarm64 |
            grep -E '"file"\s+"bins_linuxarm64_linuxarm64.zip' | cut -d '"' -f4)
        [ -n "$zip" ] || { echo "找不到 arm64 客户端下载地址" >&2; exit 1; }
        echo "下载 Steam arm64 客户端：$zip"
        curl -fL --retry 3 -o "$DL/steam-arm64.zip" "https://client-update.steamstatic.com/$zip"
        unzip -o -qq "$DL/steam-arm64.zip" -d "$STEAMROOT"
        rm -f "$DL/steam-arm64.zip"
    fi

    # 以下每次 install 都执行，可重复运行

    # zip 里有几项用 Windows 反斜杠当路径分隔符（如 steamrtarm64\libs\libcurl.so），
    # Fedora 的 unzip 会把反斜杠当成文件名的一部分，这里挪回正确位置
    local f target
    for f in "$STEAMROOT"/*\\*; do
        [ -e "$f" ] || [ -L "$f" ] || continue
        target="${f//\\//}"
        if [ -d "$f" ] && ! [ -L "$f" ]; then
            mkdir -p "$target"
            rmdir "$f" 2>/dev/null || true
        else
            mkdir -p "$(dirname "$target")"
            [ -e "$target" ] || [ -L "$target" ] || mv "$f" "$target"
            rm -f "$f"
        fi
    done

    # 走 public beta 通道，启用 arm64 客户端
    mkdir -p "$STEAMROOT/package" && echo publicbeta >"$STEAMROOT/package/beta"
    chmod -R u+rwx "$STEAMROOT/steamrtarm64/"
    ln -sfn "$STEAMROOT/steamrtarm64" "$STEAMROOT/steamrt64"
    touch "$STEAMROOT/.steam-enable-steamrt64-client"
    # 原脚本还 chmod steam.sh，但这个 zip 里没有（那是客户端自己下载的引导文件），只处理存在的
    for f in steam steamwebhelper steamwebhelper.sh gldriverquery vulkandriverquery steamsysinfo; do
        [ -e "$STEAMROOT/steamrtarm64/$f" ] && chmod +x "$STEAMROOT/steamrtarm64/$f"
    done

    # 客户端要 libvpx.so.6，Fedora 只有 .so.9：在客户端自己的库目录里放个链接，不动系统目录
    local vpx
    vpx=$(find /usr/lib64 -maxdepth 1 -name 'libvpx.so.[0-9]*' | sort -V | tail -1)
    [ -n "$vpx" ] && ln -sfn "$vpx" "$STEAMROOT/steamrtarm64/libvpx.so.6"

    # 自带的 ffmpeg 等库解压出来只有 libxxx.so，没有按 SONAME（如 libavutil.so.59）建的名字，
    # 互相依赖时找不到；补上链接（Ubuntu 上可能碰巧由系统包提供）
    local lib soname
    for lib in "$STEAMROOT"/steamrtarm64/lib*.so; do
        soname=$(readelf -d "$lib" 2>/dev/null | sed -n 's/.*(SONAME).*\[\(.*\)\]/\1/p')
        [ -n "$soname" ] && [ "$soname" != "$(basename "$lib")" ] && ln -sfn "$(basename "$lib")" "$STEAMROOT/steamrtarm64/$soname"
    done
    # Ubuntu 叫 libbz2.so.1.0，Fedora 叫 libbz2.so.1
    [ -e /usr/lib64/libbz2.so.1 ] && ln -sfn /usr/lib64/libbz2.so.1 "$STEAMROOT/steamrtarm64/libbz2.so.1.0"

    # 隔离家目录里的 ~/.steam 链接
    mkdir -p "$ARMHOME/.steam"
    ln -sfn "$STEAMROOT" "$ARMHOME/.steam/steam"
    ln -sfn "$STEAMROOT" "$ARMHOME/.steam/root"
    ln -sfn "$STEAMROOT/linuxarm64" "$ARMHOME/.steam/sdkarm64"

    # GE-Proton（arm64 版，自带 FEX）
    local compat="$STEAMROOT/compatibilitytools.d"
    if ! [ -e "$compat/$PROTON" ]; then
        mkdir -p "$compat"
        echo "下载 $PROTON（约 600 MB）"
        curl -fL --retry 3 -o "$DL/$PROTON.tar.gz" "$PROTON_URL"
        tar -xf "$DL/$PROTON.tar.gz" -C "$compat/"
        rm -f "$DL/$PROTON.tar.gz"
        # 绕过兼容性依赖检查（原脚本同样处理）
        sed -i 's#"4185400"#""#g' "$compat/$PROTON/toolmanifest.vdf"
    fi

    # 菜单项（图标用 Fedora steam 包自带的）
    mkdir -p "$(dirname "$DESKTOP")"
    cat >"$DESKTOP" <<EOF
[Desktop Entry]
Type=Application
Name=Steam (arm64)
Comment=原生 ARM Steam 客户端（beta，隔离安装）
Exec=$HOME/.local/bin/steam-arm64
Icon=steam
Terminal=false
Categories=Game;
EOF
    echo "安装完成：$ARMHOME"
}

# 出错时同时打印和弹通知（从启动器打开时看不到终端输出）
fail() {
    echo "$1" >&2
    notify-send -a "Steam (arm64)" "Steam (arm64) 无法启动" "$1" 2>/dev/null || true
    exit 1
}

# 内存（8 GB）耗尽时，内核会结束占用最大的单个进程，也就是 Steam 的 muvm 虚拟机（整个 Steam 闪退）；
# Firefox 分成很多小进程，反而躲过去。Steam 运行期间把 Firefox 各进程的 oom_score_adj 提到 800，
# 让内核先结束一个标签页（可以重新加载）。Firefox 自己会改部分进程的值，所以每 20 秒补一次。
# 调高不需要 root。2026-09-25 两次闪退时 8 GB 交换已用完：Steam 3.3 GB、Firefox 约 4.7 GB。
guard_memory() {
    local p adj
    while :; do
        for p in $(pgrep -f '^/usr/lib64/firefox/firefox( |$)'); do
            adj=$(cat "/proc/$p/oom_score_adj" 2>/dev/null) || continue
            [ "$adj" -lt 800 ] && echo 800 >"/proc/$p/oom_score_adj" 2>/dev/null
        done
        sleep 20
    done
}

# 可用内存不到 3 GB 时提醒（Steam 客户端本身要 1.5 GB 以上，开游戏更多）
warn_low_memory() {
    local avail ff
    avail=$(awk '/^MemAvailable:/ {print int($2 / 1048576 * 10) / 10}' /proc/meminfo)
    if awk -v a="$avail" 'BEGIN { exit !(a < 3) }'; then
        ff=$(ps -eo rss=,args= | awk '$2 ~ /^\/usr\/lib64\/firefox\/firefox/ {s += $1} END {printf "%.1f", s / 1048576}')
        notify-send -a "Steam (arm64)" "内存紧张：只剩 ${avail} GB 可用" \
            "Firefox 占 ${ff} GB。内存耗尽时会先结束 Firefox 标签页，但最好先关掉不用的标签。" 2>/dev/null || true
    fi
}

# 磁盘剩余不到 5 GB 时提醒：Steam 一打开就会继续未完成的下载 / 更新，写满磁盘会让一堆程序 SIGBUS 崩溃、
# 正在保存的文件被截成 0 字节（2026-09-25 下 CS2、Elden Ring 时遇到两次）
warn_low_disk() {
    local free
    free=$(df -B1M --output=avail "$HOME" | tail -1 | awk '{printf "%.1f", $1 / 1024}')
    if awk -v f="$free" 'BEGIN { exit !(f < 5) }'; then
        notify-send -u critical -a "Steam (arm64)" "磁盘只剩 ${free} GB" \
            "Steam 会继续未完成的下载和更新，写满磁盘会让程序崩溃。先在「下载」里看看还要多少空间；清理办法见 Obsidian 的「磁盘与分区」。" 2>/dev/null || true
    fi
}

run_steam() {
    warn_low_memory
    warn_low_disk
    guard_memory &
    # 不用 exec：Steam 退出后要停掉 guard_memory。进程号在这里就展开写进 trap：
    # 退出时函数早已返回，引用局部变量会是空的，guard_memory 就成了孤儿一直跑（2026-09-25 遇到过）
    # shellcheck disable=SC2064
    trap "kill $! 2>/dev/null" EXIT
    # muvm 会把 HOME 强制设回真实家目录（--env=HOME 无效），所以在虚拟机里用 env 设置，
    # 否则 ARM Steam 会读写真实的 ~/.steam（x86 Steam 的）
    muvm --mem="$MEM" -- env \
        HOME="$ARMHOME" \
        LD_LIBRARY_PATH="$STEAMROOT/steamrtarm64/${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
        "$STEAMROOT/steamrtarm64/steam" -noverifyfiles "$@"
}

case "${1:-}" in
install)
    install_client
    ;;
uninstall)
    rm -rf "$ARMHOME" "$DESKTOP"
    echo "已删除 $ARMHOME"
    ;;
*)
    # 只拦 x86 Steam；ARM Steam 已在运行时再启动一次，会交给已有实例并调出窗口
    if pgrep -f '[f]ex-steam' >/dev/null; then
        fail "x86 Steam 正在运行，请先从菜单 Steam → 退出"
    fi
    [ -e "$STEAMROOT/steamrtarm64" ] || install_client
    # steamui.so 需要 GTK2（Fedora 默认不装）
    if ! [ -e /usr/lib64/libgtk-x11-2.0.so.0 ]; then
        fail "缺少 GTK2，请先运行：sudo dnf install gtk2"
    fi
    # 第一次运行：装 Steam Runtime 4.0（需要在弹出的界面里登录）
    if ! [ -e "$STEAMROOT/steamapps/appmanifest_4185400.acf" ]; then
        run_steam steam://install/4185400
        exit
    fi
    run_steam "$@"
    ;;
esac
