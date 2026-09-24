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

run_steam() {
    exec env HOME="$ARMHOME" muvm \
        --env=HOME="$ARMHOME" \
        --env=LD_LIBRARY_PATH="$STEAMROOT/steamrtarm64/${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
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
    if pgrep -f 'fex-steam|steamrtarm64/steam' >/dev/null; then
        echo "已有 Steam 在运行，请先从菜单 Steam → 退出" >&2
        exit 1
    fi
    [ -e "$STEAMROOT/steamrtarm64" ] || install_client
    # 第一次运行：装 Steam Runtime 4.0（需要在弹出的界面里登录）
    if ! [ -e "$STEAMROOT/steamapps/appmanifest_4185400.acf" ]; then
        run_steam steam://install/4185400
    fi
    run_steam "$@"
    ;;
esac
