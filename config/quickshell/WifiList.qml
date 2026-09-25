// 快捷设置里展开的 Wi-Fi 列表（点 Wi-Fi 方块右边的 󰅂，或键盘移到它上面按 Enter）
// 展开时让 NetworkManager 扫描附近网络（约 3 秒出结果）；已连接的排最前，然后是已保存的，再按信号强弱，最多 12 个
// 已保存或开放的网络直接连接；加密的新网络在那一行下面输密码（Enter 连接，Esc 取消）
// 键盘焦点由 QuickSettings.qml 统一管理：这里只提供 focusIds（从上到下）和 activate(id)
import QtQuick
import Quickshell
import Quickshell.Networking

Item {
    id: list

    property bool active: false        // 面板开着且展开的是 Wi-Fi：只在这时扫描
    property string focusedId: ""      // 键盘焦点所在的 id（面板传进来）
    signal rowClicked(string id)       // 鼠标点了一行：面板同步焦点后再调 activate
    signal inputFinished               // 密码框收起：面板把键盘焦点拿回去
    signal closeRequested              // 打开了网络设置：面板关掉

    readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    // 同名的（同一网络的多个接入点）只留一个：已连接的优先，否则信号最强的
    readonly property var networks: {
        if (!device)
            return [];
        const best = {};
        for (const n of device.networks.values) {
            if (!n.name)
                continue;
            const b = best[n.name];
            if (!b || n.connected || (!b.connected && n.signalStrength > b.signalStrength))
                best[n.name] = n;
        }
        return Object.values(best).sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength)).slice(0, 12);
    }
    readonly property var focusIds: networks.map(n => "net:" + n.name).concat(["net:settings"])
    property string asking: ""   // 正在输密码的网络名
    property string failed: ""   // 最近一次连接失败的网络名

    implicitHeight: col.implicitHeight

    onActiveChanged: {
        if (device)
            device.scannerEnabled = active;
        if (!active)
            asking = failed = "";
    }
    onDeviceChanged: if (device)
        device.scannerEnabled = active
    onAskingChanged: if (asking === "")
        inputFinished()
    onFocusedIdChanged: ensureVisible(focusedId)

    function signalIcon(s) {
        return ["󰤟", "󰤢", "󰤥", "󰤨"][Math.max(0, Math.min(3, Math.floor(s * 4)))];
    }
    function isOpen(n) {
        return n.security === WifiSecurityType.Open || n.security === WifiSecurityType.Owe;
    }
    function activate(id) {
        if (id === "net:settings") {
            closeRequested();
            Quickshell.execDetached(["nm-connection-editor"]);
            return;
        }
        const n = networks.find(x => "net:" + x.name === id);
        if (!n || n.connected)
            return;
        failed = "";
        if (n.known || isOpen(n))
            n.connect();
        else
            asking = asking === n.name ? "" : n.name;
    }
    // 键盘移到看不见的行时滚过去
    function ensureVisible(id) {
        const i = networks.findIndex(n => "net:" + n.name === id);
        const item = i >= 0 ? rows.itemAt(i) : null;
        if (!item)
            return;
        if (item.y < flick.contentY)
            flick.contentY = item.y;
        else if (item.y + 38 > flick.contentY + flick.height)
            flick.contentY = item.y + 38 + 6 - flick.height;
    }

    Column {
        id: col
        width: parent.width
        spacing: 6

        Text {
            leftPadding: 10
            text: !Networking.wifiEnabled ? "Wi-Fi 已关闭" : list.networks.length === 0 ? "正在搜索…" : "附近的网络"
            color: Qt.rgba(1, 1, 1, 0.6)
            font.family: "Adwaita Sans"
            font.pixelSize: 12
        }

        // 最多显示约 5 行，多了滚动；左右留 4px 给焦点框（Flickable 会裁掉超出的部分）
        Flickable {
            id: flick
            width: parent.width
            height: Math.min(rowsCol.implicitHeight, 5 * 42 + 6)
            visible: list.networks.length > 0
            contentHeight: rowsCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: rowsCol
                x: 4
                width: flick.width - 8
                topPadding: 3
                bottomPadding: 3
                spacing: 4

                Repeater {
                    id: rows
                    model: list.networks

                    Column {
                        id: entry
                        required property var modelData
                        readonly property string fid: "net:" + modelData.name
                        width: rowsCol.width
                        spacing: 4

                        DeviceRow {
                            width: parent.width
                            icon: list.signalIcon(entry.modelData.signalStrength)
                            title: entry.modelData.name
                            active: entry.modelData.connected
                            status: entry.modelData.connected ? "已连接" : entry.modelData.stateChanging ? "连接中…" : list.failed === entry.modelData.name ? "连接失败" : entry.modelData.known ? "已保存" : ""
                            trailingIcon: list.isOpen(entry.modelData) ? "" : "󰌾"
                            focused: list.focusedId === entry.fid
                            onClicked: list.rowClicked(entry.fid)
                        }

                        // 密码框：只在这个网络等着输密码时出现，出现就拿到键盘焦点
                        Rectangle {
                            id: pwBox
                            visible: list.asking === entry.modelData.name
                            width: parent.width
                            height: 38
                            radius: 12
                            color: Qt.rgba(1, 1, 1, 0.08)
                            border.width: 2
                            border.color: pw.tooShort ? "#f38ba8" : "#b4befe"

                            function submit() {
                                if (pw.text.length < 8) {   // WPA 密码至少 8 位
                                    pw.tooShort = true;
                                    return;
                                }
                                entry.modelData.connectWithPsk(pw.text);
                                list.asking = "";
                            }

                            TextInput {
                                id: pw
                                property bool tooShort: false
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.right: connectButton.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                echoMode: TextInput.Password
                                color: "white"
                                selectionColor: "#b4befe"
                                selectedTextColor: "#1e1e2e"
                                font.family: "Adwaita Sans"
                                font.pixelSize: 13
                                clip: true
                                onTextChanged: tooShort = false
                                onVisibleChanged: if (visible) {
                                    text = "";
                                    forceActiveFocus();
                                }
                                Keys.onPressed: e => {
                                    if (e.key === Qt.Key_Escape) {
                                        list.asking = "";
                                        e.accepted = true;
                                    } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                                        pwBox.submit();
                                        e.accepted = true;
                                    }
                                }

                                Text {
                                    visible: pw.text === ""
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: pw.tooShort ? "至少 8 位" : "密码"
                                    color: pw.tooShort ? "#f38ba8" : Qt.rgba(1, 1, 1, 0.4)
                                    font: pw.font
                                }
                            }

                            Rectangle {
                                id: connectButton
                                anchors.right: parent.right
                                anchors.rightMargin: 5
                                anchors.verticalCenter: parent.verticalCenter
                                width: 52
                                height: 28
                                radius: 14
                                color: "#b4befe"
                                Text {
                                    anchors.centerIn: parent
                                    text: "连接"
                                    color: "#1e1e2e"
                                    font.family: "Adwaita Sans"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: pwBox.submit()
                                }
                            }
                        }

                        // 保存的密码不对 / 需要密码：弹出密码框；其他原因只标「连接失败」
                        Connections {
                            target: entry.modelData
                            function onConnectionFailed(reason) {
                                if (reason === ConnectionFailReason.NoSecrets && !list.isOpen(entry.modelData))
                                    list.asking = entry.modelData.name;
                                else
                                    list.failed = entry.modelData.name;
                            }
                        }
                    }
                }
            }
        }

        DeviceRow {
            x: 4
            width: parent.width - 8
            icon: "󰒓"
            title: "网络设置…"
            focused: list.focusedId === "net:settings"
            onClicked: list.rowClicked("net:settings")
        }
    }
}
