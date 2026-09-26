// 快捷设置面板：点顶栏右上角系统图标、Cmd+Shift+S，或 qs ipc call bar quickSettings 打开；点外面或按 Esc 关闭
// Wi-Fi / 蓝牙 / 勿扰 / 保持唤醒 / 夜间模式开关、音量和亮度滑块、电源模式；右上角锁屏和电源菜单（SessionMenu.qml）
// Wi-Fi、蓝牙方块右边的 󰅂 展开网络 / 设备列表（WifiList.qml、BluetoothList.qml）；有播放器时显示正在播放（MediaCard.qml）
// 通知在 NotificationCenter.qml（点时钟打开）
//
// 键盘优先：方向键或 hjkl 移动焦点框，Tab / Shift+Tab 按顺序走，Enter / 空格执行；
// 焦点在滑块上时 ← → 每次调 5%；Esc 先收起展开的列表，再按一次关闭面板。
// 焦点框第一次按键时才出现（那一下只显示不移动），用鼠标点了就藏起来
//
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
    property string detail: ""        // 展开的列表：wifi / bt / 空
    property string focusId: "wifi"   // 键盘焦点所在控件的 id，见 focusRows()
    property bool kbd: false          // 这次打开后用过键盘：才显示焦点框

    onOpenChanged: {
        detail = "";
        kbd = false;
        focusId = "wifi";
        if (open)
            tunedQuery.running = true;
    }

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

    readonly property var profiles: [
        { id: "saver", p: PowerProfile.PowerSaver, icon: "󰌪", name: "节能" },
        { id: "balanced", p: PowerProfile.Balanced, icon: "󰗑", name: "平衡" },
        { id: "performance", p: PowerProfile.Performance, icon: "󰓅", name: "性能" }
    ]

    // ── 键盘焦点 ──
    // 能选中的控件按屏幕上的行排：上下键换行（按比例找最近的一列），左右键在行内走
    function focusRows() {
        const rows = [["lock", "power"], ["wifi", "wifi>", "bt", "bt>"], ["dnd", "notif"], ["awake", "night"]];
        const ids = detail === "wifi" ? wifiList.focusIds : detail === "bt" ? btList.focusIds : [];
        for (const id of ids)
            rows.push([id]);
        if (media.focusIds.length > 0)
            rows.push(media.focusIds);
        rows.push(["volume"], ["brightness"], profiles.map(p => p.id));
        return rows;
    }
    function focused(id) {
        return kbd && focusId === id;
    }
    function locate(rows, id) {
        for (let r = 0; r < rows.length; r++) {
            const c = rows[r].indexOf(id);
            if (c >= 0)
                return { r: r, c: c };
        }
        return null;
    }
    function move(dr, dc) {
        const rows = focusRows();
        const p = locate(rows, focusId);
        if (!p) {   // 焦点所在的那一项没了（比如网络从列表里消失）
            focusId = detail !== "" ? detail + ">" : "wifi";
            return;
        }
        if (dc !== 0) {
            if (focusId === "volume" || focusId === "brightness")
                adjust(focusId, dc * 0.05);
            else if (p.c + dc >= 0 && p.c + dc < rows[p.r].length)
                focusId = rows[p.r][p.c + dc];
            return;
        }
        const r = p.r + dr;
        if (r >= 0 && r < rows.length)
            focusId = rows[r][Math.min(rows[r].length - 1, Math.floor(p.c * rows[r].length / rows[p.r].length))];
    }
    function step(d) {
        const flat = [].concat(...focusRows());
        const i = flat.indexOf(focusId);
        focusId = flat[((i < 0 ? 0 : i + d) + flat.length) % flat.length];
    }
    function adjust(id, delta) {
        if (id === "volume" && audio) {
            audio.muted = false;
            audio.volume = Math.max(0, Math.min(1, audio.volume + delta));
        } else if (id === "brightness")
            Brightness.set(Brightness.value + delta);
    }
    function toggleDetail(which) {
        detail = detail === which ? "" : which;
        // 用键盘展开时，焦点跳到列表第一项
        if (kbd && detail !== "") {
            const ids = detail === "wifi" ? wifiList.focusIds : btList.focusIds;
            if (ids.length > 0)
                focusId = ids[0];
        }
    }
    function activate(id) {
        switch (id) {
        case "lock":
            open = false;
            Quickshell.execDetached(["swaylock", "-f"]);
            break;
        case "power":
            open = false;
            Toggles.sessionMenu = true;
            break;
        case "wifi":
            SysInfo.setWifi(!SysInfo.wifiEnabled);
            break;
        case "bt":
            if (adapter)
                adapter.enabled = !adapter.enabled;
            break;
        case "wifi>":
        case "bt>":
            toggleDetail(id.slice(0, -1));
            break;
        case "dnd":
            Notifs.dnd = !Notifs.dnd;
            break;
        case "notif":
            open = false;
            Notifs.centerOpen = true;
            break;
        case "awake":
            Toggles.keepAwake = !Toggles.keepAwake;
            break;
        case "night":
            if (Toggles.nightLightAvailable)
                Toggles.nightLight = !Toggles.nightLight;
            break;
        case "volume":
            if (audio)
                audio.muted = !audio.muted;
            break;
        default: {
                const prof = profiles.find(p => p.id === id);
                if (prof) {
                    PowerProfiles.profile = prof.p;
                    tunedRefresh.restart();
                } else if (id.startsWith("media:"))
                    media.activate(id);
                else if (id.startsWith("net:"))
                    wifiList.activate(id);
                else if (id.startsWith("dev:"))
                    btList.activate(id);
            }
        }
    }
    // 鼠标点击：焦点跟过去（之后可以接着用键盘），焦点框藏起来
    function click(id) {
        kbd = false;
        focusId = id;
        activate(id);
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
        // 方块：点主体开关；expandable 的右边有个 󰅂，展开列表（键盘上是单独的一个焦点位置）
        component Tile: Rectangle {
            id: tile
            property string icon
            property string title
            property string subtitle
            property bool active
            property bool expandable: false
            property bool expanded: false
            property bool focused: false          // 键盘焦点在方块主体
            property bool chevronFocused: false   // 键盘焦点在 󰅂
            signal toggled
            signal expandClicked

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
                        width: tile.width - 64 - (tile.expandable ? 36 : 0)
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
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: tile.expandable ? chevron.left : parent.right
                hoverEnabled: true
                onClicked: tile.toggled()
            }

            Rectangle {
                id: chevron
                visible: tile.expandable
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 5
                width: 30
                radius: 13
                color: !chevronMouse.containsMouse ? "transparent" : tile.active ? Qt.rgba(0, 0, 0, 0.1) : Qt.rgba(1, 1, 1, 0.12)
                Behavior on color { ColorAnimation { duration: 150 } }

                // 和主体之间的分隔线
                Rectangle {
                    anchors.right: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 24
                    color: tile.active ? Qt.rgba(0.12, 0.12, 0.18, 0.25) : Qt.rgba(1, 1, 1, 0.15)
                }
                Text {
                    anchors.centerIn: parent
                    text: "󰅂"
                    rotation: tile.expanded ? 90 : 0
                    Behavior on rotation { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                    color: tile.active ? "#1e1e2e" : "white"
                    font.pixelSize: 16
                }
                MouseArea {
                    id: chevronMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: tile.expandClicked()
                }
                // 󰅂 在方块里面：方块亮着（强调色底）时，强调色的框看不见，改用深色
                FocusRing {
                    visible: tile.chevronFocused
                    anchors.margins: -1
                    radius: parent.radius + 1
                    border.color: tile.active ? "#1e1e2e" : "#b4befe"
                }
            }

            FocusRing {
                visible: tile.focused
            }
        }

        // 右上角的圆形图标按钮（锁屏、电源）
        component IconButton: Rectangle {
            id: iconButton
            property string icon
            property bool focused: false
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
            FocusRing {
                visible: iconButton.focused
            }
        }

        component Slider: Item {
            id: slider
            property string icon
            property real value
            property bool focused: false
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
                anchors.rightMargin: 4
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
                    border.color: slider.focused ? panel.accent : Qt.rgba(0, 0, 0, 0.15)
                    border.width: slider.focused ? 3 : 1
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

                // 滑块的焦点框画在轨道外面，比轨道高，把圆形拖柄也框进去
                FocusRing {
                    visible: slider.focused
                    anchors.topMargin: -8
                    anchors.bottomMargin: -8
                    anchors.leftMargin: -8
                    anchors.rightMargin: -8
                    radius: 13
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

                Keys.onPressed: e => {
                    const k = e.key;
                    if (k === Qt.Key_Escape) {
                        if (panel.detail !== "") {
                            panel.focusId = panel.detail + ">";
                            panel.detail = "";
                        } else
                            panel.open = false;
                        e.accepted = true;
                        return;
                    }
                    let action;
                    if (k === Qt.Key_Up || k === Qt.Key_K)
                        action = () => panel.move(-1, 0);
                    else if (k === Qt.Key_Down || k === Qt.Key_J)
                        action = () => panel.move(1, 0);
                    else if (k === Qt.Key_Left || k === Qt.Key_H)
                        action = () => panel.move(0, -1);
                    else if (k === Qt.Key_Right || k === Qt.Key_L)
                        action = () => panel.move(0, 1);
                    else if (k === Qt.Key_Tab)
                        action = () => panel.step(1);
                    else if (k === Qt.Key_Backtab)
                        action = () => panel.step(-1);
                    else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space)
                        action = () => panel.activate(panel.focusId);
                    else
                        return;
                    e.accepted = true;
                    if (!panel.kbd)
                        panel.kbd = true;   // 第一次按键只把焦点框显示出来
                    else
                        action();
                }

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
                            focused: panel.focused("lock")
                            onClicked: panel.click("lock")
                        }
                        IconButton {
                            icon: "󰐥"
                            focused: panel.focused("power")
                            onClicked: panel.click("power")
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
                        expandable: true
                        expanded: panel.detail === "wifi"
                        focused: panel.focused("wifi")
                        chevronFocused: panel.focused("wifi>")
                        onToggled: panel.click("wifi")
                        onExpandClicked: panel.click("wifi>")
                    }
                    Tile {
                        width: (parent.width - 10) / 2
                        icon: panel.adapter && panel.adapter.enabled ? "󰂯" : "󰂲"
                        title: "蓝牙"
                        subtitle: !panel.adapter ? "没有适配器" : !panel.adapter.enabled ? "已关闭" : panel.btConnected.length > 0 ? panel.btConnected.map(d => d.name).join("、") : "未连接"
                        active: panel.adapter !== null && panel.adapter.enabled
                        expandable: true
                        expanded: panel.detail === "bt"
                        focused: panel.focused("bt")
                        chevronFocused: panel.focused("bt>")
                        onToggled: panel.click("bt")
                        onExpandClicked: panel.click("bt>")
                    }
                    Tile {
                        width: (parent.width - 10) / 2
                        icon: "󰂛"
                        title: "勿扰"
                        subtitle: Notifs.dnd ? "通知已静音" : "关闭"
                        active: Notifs.dnd
                        focused: panel.focused("dnd")
                        onToggled: panel.click("dnd")
                    }
                    Tile {
                        width: (parent.width - 10) / 2
                        icon: "󰂚"
                        title: "通知"
                        subtitle: Notifs.list.length > 0 ? Notifs.list.length + " 条" : "没有通知"
                        focused: panel.focused("notif")
                        onToggled: panel.click("notif")
                    }
                    // 看视频、跑长任务时不自动锁屏；开着时顶栏时钟旁有个咖啡杯
                    Tile {
                        width: (parent.width - 10) / 2
                        icon: "󰅶"
                        title: "保持唤醒"
                        subtitle: Toggles.keepAwake ? "不会自动锁屏" : "关闭"
                        active: Toggles.keepAwake
                        focused: panel.focused("awake")
                        onToggled: panel.click("awake")
                    }
                    Tile {
                        width: (parent.width - 10) / 2
                        icon: "󰖔"
                        title: "夜间模式"
                        // 方块只放得下 7 个字左右；没装时要 sudo dnf install wlsunset
                        subtitle: !Toggles.nightLightAvailable ? "未安装" : Toggles.nightLight ? "暖色 4000K" : "关闭"
                        active: Toggles.nightLight
                        focused: panel.focused("night")
                        onToggled: panel.click("night")
                    }
                }

                // 展开的 Wi-Fi / 蓝牙列表
                Rectangle {
                    width: parent.width
                    visible: panel.detail !== ""
                    implicitHeight: (panel.detail === "wifi" ? wifiList.implicitHeight : btList.implicitHeight) + 16
                    radius: 18
                    color: Qt.rgba(1, 1, 1, 0.06)

                    WifiList {
                        id: wifiList
                        x: 8
                        y: 8
                        width: parent.width - 16
                        visible: panel.detail === "wifi"
                        active: panel.open && panel.detail === "wifi"
                        focusedId: panel.kbd ? panel.focusId : ""
                        onRowClicked: id => panel.click(id)
                        onInputFinished: content.forceActiveFocus()
                        onCloseRequested: panel.open = false
                    }
                    BluetoothList {
                        id: btList
                        x: 8
                        y: 8
                        width: parent.width - 16
                        visible: panel.detail === "bt"
                        active: panel.open && panel.detail === "bt"
                        focusedId: panel.kbd ? panel.focusId : ""
                        onRowClicked: id => panel.click(id)
                    }
                }

                // 正在播放（没有播放器时不显示）
                MediaCard {
                    id: media
                    width: parent.width
                    active: panel.open
                    focusedId: panel.kbd ? panel.focusId : ""
                    onButtonClicked: id => panel.click(id)
                }

                Slider {
                    width: parent.width
                    icon: !panel.audio ? "󰕿" : panel.audio.muted ? "󰝟" : "󰕾"
                    value: panel.audio && !panel.audio.muted ? panel.audio.volume : 0
                    focused: panel.focused("volume")
                    onMoved: v => {
                        if (!panel.audio)
                            return;
                        panel.audio.muted = false;
                        panel.audio.volume = v;
                    }
                    onIconClicked: panel.click("volume")
                }

                Slider {
                    width: parent.width
                    icon: "󰃠"
                    value: Brightness.value
                    focused: panel.focused("brightness")
                    onMoved: v => Brightness.set(v)
                }

                // 电源模式（tuned-ppd 提供 PowerProfiles 接口）；gaming 等自定义模式不高亮任何按钮，下面单独显示名字
                Row {
                    id: profileRow
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: panel.profiles

                        Rectangle {
                            required property var modelData
                            readonly property bool current: panel.tunedMap[panel.tuned] === modelData.p
                            width: (profileRow.width - 12) / 3
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
                                onClicked: panel.click(modelData.id)
                            }
                            FocusRing {
                                visible: panel.focused(modelData.id)
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
