// 快捷设置面板：点顶栏右上角系统图标打开（或 qs ipc call bar quickSettings），点外面或按 Esc 关闭
// Wi-Fi / 蓝牙 / 勿扰 / 保持唤醒 / 夜间模式开关、音量和亮度滑块、电源模式；右上角锁屏和电源菜单（SessionMenu.qml）
// 通知在 NotificationCenter.qml（点时钟打开）
// 用 layer-shell 窗口而不是 PopupWindow：带 grabFocus 的弹出窗口必须由真实点击触发，
// 从 IPC / 快捷键打开会被 niri 立刻撤掉。点外面关闭靠下面一层全屏透明窗口。
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Scope {
    id: panel

    required property var screen
    property bool open: false
    onOpenChanged: if (open)
        tunedQuery.running = true

    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btConnected: Bluetooth.devices.values.filter(d => d.connected)
    readonly property color accent: "#b4befe"   // 和 niri 的 focus-ring 同色

    // 电源模式按 tuned 的实际模式显示：用 tuned-adm 手动切到 gaming 等模式时，
    // PowerProfiles 接口只会报 unknown（Quickshell 会停在默认值，误显示成「平衡」）
    property string tuned: ""
    readonly property var tunedMap: ({
            "powersave": PowerProfile.PowerSaver,
            "balanced": PowerProfile.Balanced,
            "balanced-battery": PowerProfile.Balanced,
            "throughput-performance": PowerProfile.Performance
        })
    Process {
        id: tunedQuery
        command: ["tuned-adm", "active"]
        stdout: StdioCollector {
            onStreamFinished: panel.tuned = text.replace(/^.*:\s*/, "").trim()
        }
    }
    Timer {
        id: tunedRefresh
        interval: 1000
        onTriggered: tunedQuery.running = true
    }



    // 面板外的点击：关闭
    PanelWindow {
        screen: panel.screen
        visible: panel.open
        WlrLayershell.namespace: "quickshell-dismiss"
        WlrLayershell.layer: WlrLayer.Top
        exclusionMode: ExclusionMode.Ignore
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: panel.open = false
        }
    }

    PanelWindow {
        id: win
        screen: panel.screen
        visible: panel.open
        WlrLayershell.namespace: "quickshell-quicksettings"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore
        anchors {
            top: true
            right: true
        }
        // 顶栏下方 8px，右边和顶栏对齐
        margins {
            top: 6 + 32 + 8
            right: 10
        }
        implicitWidth: 340
        implicitHeight: content.implicitHeight + 32
        color: "transparent"
        BackgroundEffect.blurRegion: Region { item: bg; radius: 22 }

        // ── 小组件 ──
        component Tile: Rectangle {
            id: tile
            property string icon
            property string title
            property string subtitle
            property bool active
            signal toggled

            implicitHeight: 56
            radius: 18
            color: active ? panel.accent : tileMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.1)
            Behavior on color { ColorAnimation { duration: 150 } }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Text {
                    text: tile.icon
                    color: tile.active ? "#1e1e2e" : "white"
                    font.pixelSize: 20
                    anchors.verticalCenter: parent.verticalCenter
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: tile.title
                        color: tile.active ? "#1e1e2e" : "white"
                        font.family: "Adwaita Sans"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    Text {
                        visible: text !== ""
                        width: tile.width - 64
                        elide: Text.ElideRight
                        text: tile.subtitle
                        color: tile.active ? Qt.rgba(0.12, 0.12, 0.18, 0.75) : Qt.rgba(1, 1, 1, 0.6)
                        font.family: "Adwaita Sans"
                        font.pixelSize: 12
                    }
                }
            }

            MouseArea {
                id: tileMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: tile.toggled()
            }
        }

        // 右上角的圆形图标按钮（锁屏、电源）
        component IconButton: Rectangle {
            id: iconButton
            property string icon
            signal clicked

            implicitWidth: 32
            implicitHeight: 32
            radius: 16
            color: iconMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.1)
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.centerIn: parent
                text: iconButton.icon
                color: "white"
                font.pixelSize: 16
            }
            MouseArea {
                id: iconMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: iconButton.clicked()
            }
        }

        component Slider: Item {
            id: slider
            property string icon
            property real value
            signal moved(real v)
            signal iconClicked

            implicitHeight: 36

            Text {
                id: sliderIcon
                width: 28
                text: slider.icon
                color: "white"
                font.pixelSize: 18
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    onClicked: slider.iconClicked()
                }
            }

            Rectangle {
                id: track
                anchors.left: sliderIcon.right
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 10
                radius: 5
                color: Qt.rgba(1, 1, 1, 0.15)

                Rectangle {
                    width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, slider.value)))
                    height: parent.height
                    radius: parent.radius
                    color: "white"
                }
                Rectangle {
                    x: Math.max(0, Math.min(parent.width - width, parent.width * slider.value - width / 2))
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    radius: 10
                    color: "white"
                    border.color: Qt.rgba(0, 0, 0, 0.15)
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -10
                    function update(x) {
                        slider.moved(Math.max(0, Math.min(1, (x - 10) / track.width)));
                    }
                    onPressed: m => update(m.x)
                    onPositionChanged: m => { if (pressed) update(m.x); }
                }
            }
        }

        // ── 面板 ──
        Rectangle {
            id: bg
            anchors.fill: parent
            radius: 22
            color: Qt.rgba(0.08, 0.08, 0.1, 0.6)
            border.color: Qt.rgba(1, 1, 1, 0.08)
            border.width: 1

            Column {
                id: content
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14
                focus: true
                Keys.onEscapePressed: panel.open = false

                // 顶部：左边电池，右边锁屏和电源菜单
                Item {
                    width: parent.width
                    implicitHeight: 32

                    Row {
                        readonly property var dev: UPower.displayDevice
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        visible: dev.isLaptopBattery
                        Text {
                            text: "󰁹  " + Math.round(parent.dev.percentage * 100) + "%"
                            color: "white"
                            font.family: "Adwaita Sans"
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Text {
                            readonly property var dev: UPower.displayDevice
                            anchors.verticalCenter: parent.verticalCenter
                            text: dev.state === UPowerDeviceState.Charging ? "正在充电" : dev.state === UPowerDeviceState.FullyCharged ? "已充满" : dev.timeToEmpty > 0 ? "剩余 " + Math.floor(dev.timeToEmpty / 3600) + " 小时 " + Math.round(dev.timeToEmpty % 3600 / 60) + " 分" : ""
                            color: Qt.rgba(1, 1, 1, 0.6)
                            font.family: "Adwaita Sans"
                            font.pixelSize: 13
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        IconButton {
                            icon: "󰌾"
                            onClicked: {
                                panel.open = false;
                                Quickshell.execDetached(["swaylock", "-f"]);
                            }
                        }
                        IconButton {
                            icon: "󰐥"
                            onClicked: {
                                panel.open = false;
                                Toggles.sessionMenu = true;
                            }
                        }
                    }
                }

                Grid {
                    columns: 2
                    spacing: 10
                    width: parent.width

                    Tile {
                        width: (parent.width - 10) / 2
                        icon: SysInfo.wifiEnabled ? "󰤨" : "󰤮"
                        title: "Wi-Fi"
                        subtitle: !SysInfo.wifiEnabled ? "已关闭" : SysInfo.netState === "wifi" ? SysInfo.wifiSsid : "未连接"
                        active: SysInfo.wifiEnabled
                        onToggled: SysInfo.setWifi(!SysInfo.wifiEnabled)
                    }
                    Tile {
                        width: (parent.width - 10) / 2
                        visible: panel.adapter !== null
                        icon: panel.adapter && panel.adapter.enabled ? "󰂯" : "󰂲"
                        title: "蓝牙"
                        subtitle: !panel.adapter || !panel.adapter.enabled ? "已关闭" : panel.btConnected.length > 0 ? panel.btConnected.map(d => d.name).join("、") : "未连接"
                        active: panel.adapter !== null && panel.adapter.enabled
                        onToggled: panel.adapter.enabled = !panel.adapter.enabled
                    }
                    Tile {
                        width: (parent.width - 10) / 2
                        icon: "󰂛"
                        title: "勿扰"
                        subtitle: Notifs.dnd ? "通知已静音" : "关闭"
                        active: Notifs.dnd
                        onToggled: Notifs.dnd = !Notifs.dnd
                    }
                    Tile {
                        width: (parent.width - 10) / 2
                        icon: "󰂚"
                        title: "通知"
                        subtitle: Notifs.list.length > 0 ? Notifs.list.length + " 条" : "没有通知"
                        onToggled: {
                            panel.open = false;
                            Notifs.centerOpen = true;
                        }
                    }
                    // 看视频、跑长任务时不自动锁屏；开着时顶栏时钟旁有个咖啡杯
                    Tile {
                        width: (parent.width - 10) / 2
                        icon: "󰅶"
                        title: "保持唤醒"
                        subtitle: Toggles.keepAwake ? "不会自动锁屏" : "关闭"
                        active: Toggles.keepAwake
                        onToggled: Toggles.keepAwake = !Toggles.keepAwake
                    }
                    Tile {
                        width: (parent.width - 10) / 2
                        icon: "󰖔"
                        title: "夜间模式"
                        // 方块只放得下 7 个字左右；没装时要 sudo dnf install wlsunset
                        subtitle: !Toggles.nightLightAvailable ? "未安装" : Toggles.nightLight ? "暖色 4000K" : "关闭"
                        active: Toggles.nightLight
                        onToggled: if (Toggles.nightLightAvailable)
                            Toggles.nightLight = !Toggles.nightLight
                    }
                }

                Slider {
                    width: parent.width
                    icon: !panel.audio ? "󰕿" : panel.audio.muted ? "󰝟" : "󰕾"
                    value: panel.audio && !panel.audio.muted ? panel.audio.volume : 0
                    onMoved: v => {
                        if (!panel.audio)
                            return;
                        panel.audio.muted = false;
                        panel.audio.volume = v;
                    }
                    onIconClicked: if (panel.audio) panel.audio.muted = !panel.audio.muted
                }

                Slider {
                    width: parent.width
                    icon: "󰃠"
                    value: Brightness.value
                    onMoved: v => Brightness.set(v)
                }

                // 电源模式（tuned-ppd 提供 PowerProfiles 接口）；gaming 等自定义模式不高亮任何按钮，下面单独显示名字
                Row {
                    id: profiles
                    width: parent.width
                    spacing: 6
                    readonly property var items: [
                        { p: PowerProfile.PowerSaver, icon: "󰌪", name: "节能" },
                        { p: PowerProfile.Balanced, icon: "󰗑", name: "平衡" },
                        { p: PowerProfile.Performance, icon: "󰓅", name: "性能" }
                    ]

                    Repeater {
                        model: profiles.items

                        Rectangle {
                            required property var modelData
                            readonly property bool current: panel.tunedMap[panel.tuned] === modelData.p
                            width: (profiles.width - 12) / 3
                            height: 36
                            radius: 18
                            color: current ? panel.accent : profMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(1, 1, 1, 0.1)
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon + "  " + modelData.name
                                color: parent.current ? "#1e1e2e" : "white"
                                font.family: "Adwaita Sans"
                                font.pixelSize: 13
                                font.bold: true
                            }
                            MouseArea {
                                id: profMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    PowerProfiles.profile = modelData.p;
                                    tunedRefresh.restart();
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: panel.tuned !== "" && panel.tunedMap[panel.tuned] === undefined
                    text: "当前 tuned 模式：" + panel.tuned
                    color: Qt.rgba(1, 1, 1, 0.6)
                    font.family: "Adwaita Sans"
                    font.pixelSize: 12
                }
            }
        }
    }
}
