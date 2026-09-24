// 顶栏：分开的胶囊，每个胶囊背后单独模糊（BackgroundEffect.blurRegion 按胶囊形状申请）
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower

PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "quickshell-bar"
    anchors {
        top: true
        left: true
        right: true
    }
    // 浮动胶囊：四周留和 niri 窗口间隙（gaps 10）一样的边距
    margins {
        top: 6
        left: 10
        right: 10
    }
    implicitHeight: 32
    color: "transparent"

    // 只模糊胶囊底下（隐藏的胶囊宽度为 0，不占模糊区域）
    BackgroundEffect.blurRegion: Region {
        Region { item: wsPill; radius: 16 }
        Region { item: titlePill; radius: 16 }
        Region { item: clockPill; radius: 16 }
        Region { item: mediaPill; radius: 16 }
        Region { item: memPill; radius: 16 }
        Region { item: speedPill; radius: 16 }
        Region { item: trayPill; radius: 16 }
        Region { item: sysPill; radius: 16 }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    function sh(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    // 秒 -> 「2 小时 5 分」
    function duration(s) {
        const h = Math.floor(s / 3600), m = Math.round(s % 3600 / 60);
        return h > 0 ? h + " 小时 " + m + " 分" : m + " 分钟";
    }

    // 媒体：优先正在播放的，其次任意可控制的
    readonly property var player: {
        const ps = Mpris.players.values;
        return ps.find(p => p.isPlaying) ?? ps.find(p => p.canControl) ?? null;
    }

    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

    // ── 左：工作区、窗口标题 ──
    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // 工作区：圆点，当前的是长条；滚轮切换
        Pill {
            id: wsPill
            padding: 11
            spacing: 6
            hoverable: false
            onWheel: w => bar.sh("niri msg action focus-workspace-" + (w.angleDelta.y > 0 ? "up" : "down"))

            Repeater {
                model: Niri.workspaces

                Rectangle {
                    required property var modelData
                    width: modelData.is_active ? 30 : 8
                    height: 8
                    radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: modelData.is_active ? "white" : wsMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(1, 1, 1, 0.45)
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }

                    MouseArea {
                        id: wsMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        onClicked: Niri.focusWorkspace(modelData.idx)
                    }
                }
            }
        }

        Pill {
            id: titlePill
            hoverable: false
            visible: Niri.windowTitle !== ""
            width: visible ? implicitWidth : 0
            // 截断了才提示完整标题
            tooltip: Niri.windowTitle.length > 60 ? Niri.windowTitle : ""

            Label {
                text: Niri.windowTitle.length > 60 ? Niri.windowTitle.slice(0, 59) + "…" : Niri.windowTitle
            }
        }
    }

    // ── 中：时钟，点击打开通知中心 ──
    Pill {
        id: clockPill
        anchors.centerIn: parent
        tooltip: Qt.locale("zh_CN").toString(clock.date, "yyyy年M月d日 dddd")
        onClicked: bar.sh("swaync-client -t -sw")

        Label {
            text: Qt.formatDateTime(clock.date, "M月d日  HH:mm")
        }
    }

    // ── 右：媒体、内存、网速、托盘、系统图标 ──
    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // 媒体：左键播放/暂停，右键下一首，中键上一首
        Pill {
            id: mediaPill
            visible: bar.player !== null
            width: visible ? implicitWidth : 0
            tooltip: bar.player ? [bar.player.trackTitle, [bar.player.trackArtist, bar.player.trackAlbum].filter(s => s).join(" — "), bar.player.identity].filter(s => s).join("\n") : ""
            onClicked: m => {
                if (!bar.player)
                    return;
                if (m.button === Qt.RightButton)
                    bar.player.next();
                else if (m.button === Qt.MiddleButton)
                    bar.player.previous();
                else
                    bar.player.togglePlaying();
            }

            Label {
                readonly property string track: bar.player ? [bar.player.trackTitle, bar.player.trackArtist].filter(s => s).join(" - ") : ""
                text: (bar.player && bar.player.isPlaying ? "󰏤  " : "󰐊  ") + (track.length > 40 ? track.slice(0, 39) + "…" : track)
            }
        }

        Pill {
            id: memPill
            tooltip: "已用 " + SysInfo.memUsedGiB.toFixed(1) + " / " + SysInfo.memTotalGiB.toFixed(1) + " GiB"
            Label { text: "󰍛  " + SysInfo.memPercent + "%" }
        }

        Pill {
            id: speedPill
            hoverable: false
            visible: SysInfo.netState !== "none"
            width: visible ? implicitWidth : 0
            Label { text: "↑" + SysInfo.netUp + "  ↓" + SysInfo.netDown }
        }

        Pill {
            id: trayPill
            spacing: 14
            hoverable: false
            visible: SystemTray.items.values.length > 0
            width: visible ? implicitWidth : 0

            Repeater {
                model: SystemTray.items

                IconImage {
                    id: trayIcon
                    required property var modelData
                    source: modelData.icon
                    implicitSize: 16
                    anchors.verticalCenter: parent.verticalCenter

                    // symbolic 图标是深色的，GTK 会自动染成文字颜色，Qt 不会：手动染白
                    layer.enabled: String(source).includes("symbolic")
                    layer.effect: MultiEffect {
                        brightness: 1.0
                    }

                    MouseArea {
                        id: trayMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: m => {
                            const item = trayIcon.modelData;
                            if (m.button === Qt.MiddleButton)
                                item.secondaryActivate();
                            else if (m.button === Qt.RightButton || item.onlyMenu) {
                                const p = trayIcon.mapToItem(null, 0, trayIcon.height + 10);
                                item.display(bar, p.x, p.y);
                            } else
                                item.activate();
                        }
                    }

                    Tooltip {
                        target: trayIcon
                        text: trayIcon.modelData.tooltipTitle || trayIcon.modelData.title
                        hovered: trayMouse.containsMouse
                    }
                }
            }
        }

        // 系统图标组：蓝牙、网络、音量、电池；点击打开快捷设置面板
        Pill {
            id: sysPill
            onClicked: m => { if (m.button === Qt.LeftButton) quick.open = !quick.open; }
            onWheel: w => { if (bar.audio) bar.audio.volume = Math.max(0, Math.min(1, bar.audio.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05))); }

            // 蓝牙：关 󰂲 / 开 󰂯 / 已连接 󰂱；没有适配器时不显示
            SysIcon {
                readonly property var adapter: Bluetooth.defaultAdapter
                readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)
                visible: adapter !== null
                rightPadding: 14
                text: !adapter || !adapter.enabled ? "󰂲" : connected.length > 0 ? "󰂱" : "󰂯"
                tooltip: !adapter || !adapter.enabled ? "蓝牙已关闭" : connected.length === 0 ? "蓝牙已开启，未连接设备" : connected.map(d => d.name + (d.batteryAvailable ? "  " + Math.round(d.battery * 100) + "%" : "")).join("\n")
                onClicked: quick.open = !quick.open
            }

            SysIcon {
                rightPadding: 14
                text: SysInfo.netState === "ethernet" ? "󰈀" : SysInfo.netState === "none" ? "󰤮" : ["󰤟", "󰤢", "󰤥", "󰤨"][Math.min(3, Math.floor(SysInfo.wifiSignal / 25))]
                tooltip: SysInfo.netState === "wifi" ? SysInfo.wifiSsid + "（" + SysInfo.wifiSignal + "%）" : SysInfo.netState === "ethernet" ? "有线网络" : SysInfo.wifiEnabled ? "未连接" : "Wi-Fi 已关闭"
                onClicked: quick.open = !quick.open
            }

            // 音量；右键静音，滚轮调节
            SysIcon {
                rightPadding: 14
                text: !bar.audio ? "󰕿" : bar.audio.muted ? "󰝟" : ["󰕿", "󰖀", "󰕾"][Math.min(2, Math.floor(bar.audio.volume * 3))]
                tooltip: !bar.audio ? "" : bar.audio.muted ? "已静音" : "音量 " + Math.round(bar.audio.volume * 100) + "%"
                onClicked: m => {
                    if (m.button === Qt.RightButton) {
                        if (bar.audio)
                            bar.audio.muted = !bar.audio.muted;
                    } else
                        quick.open = !quick.open;
                }
            }

            // 电池：≤20% 黄色，≤10% 红色（充电时不变色）
            SysIcon {
                readonly property var dev: UPower.displayDevice
                readonly property int pct: Math.round(dev.percentage * 100)
                readonly property bool charging: dev.state === UPowerDeviceState.Charging
                visible: dev.isLaptopBattery
                color: charging ? "white" : pct <= 10 ? "#ff7b63" : pct <= 20 ? "#f8e45c" : "white"
                text: (charging ? "󰂄" : ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][Math.min(9, Math.floor(pct / 10))]) + " " + pct + "%"
                tooltip: dev.state === UPowerDeviceState.FullyCharged ? "已充满" : charging ? (dev.timeToFull > 0 ? "充满还需 " + bar.duration(dev.timeToFull) : "正在充电") : (dev.timeToEmpty > 0 ? "剩余 " + bar.duration(dev.timeToEmpty) : "")
                onClicked: quick.open = !quick.open
            }
        }
    }

    QuickSettings {
        id: quick
        screen: bar.screen
    }

    // 外部调用：qs ipc call bar quickSettings（可绑快捷键）
    IpcHandler {
        target: "bar"
        function quickSettings(): void { quick.open = !quick.open; }
    }
}
