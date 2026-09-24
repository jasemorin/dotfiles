// 顶部状态栏（取代 waybar）：分开的胶囊，每个胶囊背后单独模糊
// waybar 做不到这点：它不支持 ext-background-effect，niri 只能模糊整条栏的矩形，胶囊之间会有一条磨砂横带。
// 这里用 BackgroundEffect.blurRegion 把胶囊的圆角形状告诉 niri，只模糊胶囊底下。
// 需要 Quickshell ≥ 0.3（COPR errornointernet/quickshell）；在 niri 下由 niri/config.kdl 启动
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower

ShellRoot {
    id: root

    // ── niri 状态：监听事件流，有变化就重新查一次工作区和当前窗口 ──
    property var workspaces: []
    property string windowTitle: ""

    function sh(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    Process {
        id: events
        running: true
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: refresh.restart()
        }
        // niri 重启等情况下断开后自动重连
        onRunningChanged: if (!running) reconnect.start()
    }
    Timer {
        id: reconnect
        interval: 1000
        onTriggered: events.running = true
    }
    Timer {
        id: refresh
        interval: 30
        onTriggered: {
            wsQuery.running = true;
            winQuery.running = true;
        }
    }
    Process {
        id: wsQuery
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: root.workspaces = JSON.parse(text).sort((a, b) => a.idx - b.idx)
        }
    }
    Process {
        id: winQuery
        command: ["niri", "msg", "--json", "focused-window"]
        stdout: StdioCollector {
            onStreamFinished: {
                const w = JSON.parse(text);
                root.windowTitle = w && w.title ? w.title : "";
            }
        }
    }

    // ── 内存、网速：读 /proc ──
    property int memPercent: 0
    property string netUp: "0.0B/s"
    property string netDown: "0.0B/s"
    property var lastNet: null

    // 和 waybar 的 {bandwidthUpBytes} 一样：1000 进制，一位小数
    function speed(bytes) {
        const units = ["B", "kB", "MB", "GB"];
        let i = 0;
        while (bytes >= 1000 && i < units.length - 1) {
            bytes /= 1000;
            i++;
        }
        return bytes.toFixed(1) + units[i] + "/s";
    }

    Process {
        id: memQuery
        command: ["cat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                const get = k => parseInt(text.match(new RegExp("^" + k + ":\\s+(\\d+)", "m"))[1]);
                const total = get("MemTotal");
                root.memPercent = Math.round((total - get("MemAvailable")) / total * 100);
            }
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: memQuery.running = true
    }

    Process {
        id: netQuery
        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                let rx = 0, tx = 0;
                for (const line of text.split("\n").slice(2)) {
                    const f = line.trim().split(/[:\s]+/);
                    if (f.length < 10 || f[0] === "lo")
                        continue;
                    rx += Number(f[1]);
                    tx += Number(f[9]);
                }
                const now = Date.now();
                if (root.lastNet) {
                    const dt = (now - root.lastNet.t) / 1000;
                    root.netDown = root.speed(Math.max(0, rx - root.lastNet.rx) / dt);
                    root.netUp = root.speed(Math.max(0, tx - root.lastNet.tx) / dt);
                }
                root.lastNet = { t: now, rx: rx, tx: tx };
            }
        }
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netQuery.running = true
    }

    // ── 网络图标：nmcli 查 Wi-Fi 信号 ──
    property string netState: "none"   // wifi / ethernet / none
    property int wifiSignal: 0

    Process {
        id: nmQuery
        command: ["sh", "-c", "nmcli -t -f IN-USE,SIGNAL dev wifi list --rescan no | sed -n 's/^\\*://p' | head -1; nmcli -t -f TYPE,STATE dev | grep -c '^ethernet:connected$'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const [signal, eth] = text.trim().split("\n");
                if (signal && !isNaN(parseInt(signal))) {
                    root.netState = "wifi";
                    root.wifiSignal = parseInt(signal);
                } else {
                    root.netState = parseInt(eth) > 0 ? "ethernet" : "none";
                }
            }
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: nmQuery.running = true
    }

    // 音量：要跟踪默认输出设备，才能读到 volume / muted
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ── 栏 ──
    Variants {
        model: Quickshell.screens

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
                Region { item: memPill; radius: 16 }
                Region { item: speedPill; radius: 16 }
                Region { item: trayPill; radius: 16 }
                Region { item: sysPill; radius: 16 }
            }

            // 文字样式
            component Label: Text {
                color: "white"
                font.family: "Adwaita Sans"
                font.pixelSize: 14
                font.bold: true
                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            }

            // 左：工作区、窗口标题
            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                // 工作区：圆点，当前的是长条
                Pill {
                    id: wsPill
                    padding: 11
                    spacing: 6
                    hoverable: false

                    Repeater {
                        model: root.workspaces

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
                                onClicked: root.sh("niri msg action focus-workspace " + modelData.idx)
                            }
                        }
                    }
                }

                Pill {
                    id: titlePill
                    hoverable: false
                    visible: root.windowTitle !== ""
                    width: visible ? implicitWidth : 0

                    Label {
                        text: root.windowTitle.length > 60 ? root.windowTitle.slice(0, 59) + "…" : root.windowTitle
                    }
                }
            }

            // 中：时钟，点击打开通知面板
            Pill {
                id: clockPill
                anchors.centerIn: parent
                onClicked: root.sh("swaync-client -t -sw")

                Label {
                    text: Qt.formatDateTime(clock.date, "M月d日  HH:mm")
                }
            }

            // 右：内存、网速、托盘、系统图标
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Pill {
                    id: memPill
                    Label { text: "󰍛  " + root.memPercent + "%" }
                }

                Pill {
                    id: speedPill
                    hoverable: false
                    visible: root.netState !== "none"
                    width: visible ? implicitWidth : 0
                    Label { text: "↑" + root.netUp + "  ↓" + root.netDown }
                }

                Pill {
                    id: trayPill
                    spacing: 14
                    visible: SystemTray.items.values.length > 0
                    width: visible ? implicitWidth : 0

                    Repeater {
                        model: SystemTray.items

                        IconImage {
                            id: trayIcon
                            required property var modelData
                            required property int index
                            source: modelData.icon
                            implicitSize: 16
                            anchors.verticalCenter: parent.verticalCenter

                            // symbolic 图标是深色的，GTK 会自动染成文字颜色，Qt 不会：手动染白
                            layer.enabled: String(source).includes("symbolic")
                            layer.effect: MultiEffect {
                                brightness: 1.0
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
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
                        }
                    }
                }

                // 系统图标组：蓝牙、网络、音量、电池；点击打开通知面板
                Pill {
                    id: sysPill
                    onClicked: m => {
                        if (m.button === Qt.LeftButton)
                            root.sh("swaync-client -t -sw");
                    }

                    // 蓝牙：关 󰂲 / 开 󰂯 / 已连接 󰂱；没有适配器时不显示
                    Label {
                        readonly property var adapter: Bluetooth.defaultAdapter
                        visible: adapter !== null
                        rightPadding: 14
                        text: !adapter || !adapter.enabled ? "󰂲" : Bluetooth.devices.values.some(d => d.connected) ? "󰂱" : "󰂯"
                    }

                    Label {
                        rightPadding: 14
                        text: root.netState === "ethernet" ? "󰈀" : root.netState === "none" ? "󰤮" : ["󰤟", "󰤢", "󰤥", "󰤨"][Math.min(3, Math.floor(root.wifiSignal / 25))]
                    }

                    // 音量；右键静音
                    Label {
                        id: vol
                        readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
                        rightPadding: 14
                        text: !audio ? "󰕿" : audio.muted ? "󰝟" : ["󰕿", "󰖀", "󰕾"][Math.min(2, Math.floor(audio.volume * 3))]

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            onClicked: if (vol.audio) vol.audio.muted = !vol.audio.muted
                        }
                    }

                    // 电池：≤20% 黄色，≤10% 红色（充电时不变色）
                    Label {
                        readonly property var dev: UPower.displayDevice
                        readonly property int pct: Math.round(dev.percentage * 100)
                        readonly property bool charging: dev.state === UPowerDeviceState.Charging
                        visible: dev.isLaptopBattery
                        color: charging ? "white" : pct <= 10 ? "#ff7b63" : pct <= 20 ? "#f8e45c" : "white"
                        text: (charging ? "󰂄" : ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][Math.min(9, Math.floor(pct / 10))]) + " " + pct + "%"
                    }
                }
            }
        }
    }
}
