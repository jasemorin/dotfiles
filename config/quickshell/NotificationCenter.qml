// 通知中心：点顶栏时钟打开（或 qs ipc call bar notifications），在时钟正下方；点外面或按 Esc 关闭
// 上面是月历，下面是通知历史、勿扰开关、全部清除
// 键盘（Cmd+Shift+N 打开）：j k / ↑↓ 选通知（第一次按只显示焦点框），Enter 执行，x / Delete 删除，
// Shift+Delete 全部清除，d 勿扰，h l / ←→ 翻月，. 回到本月，Esc 关闭
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: center

    required property var screen
    readonly property color accent: "#b4befe"   // 和 niri 的 focus-ring 同色
    property bool kbd: false   // 这次打开后用过键盘：才显示焦点框和按键提示
    property int sel: 0        // 键盘选中的通知（Notifs.list 的下标）

    function select(i) {
        const n = Notifs.list.length;
        if (n === 0)
            return;
        sel = Math.max(0, Math.min(n - 1, i));
        list.positionViewAtIndex(sel, ListView.Contain);
    }
    function shiftMonth(d) {
        cal.month = d === 0 ? new Date(clock.date.getFullYear(), clock.date.getMonth(), 1) : new Date(cal.month.getFullYear(), cal.month.getMonth() + d, 1);
    }
    function handleKey(e) {
        const k = e.key, n = Notifs.list[sel];
        if (k === Qt.Key_Escape)
            Notifs.centerOpen = false;
        else if (k === Qt.Key_J || k === Qt.Key_Down || k === Qt.Key_K || k === Qt.Key_Up) {
            if (!kbd)
                kbd = true;   // 第一次按键只显示焦点框
            else
                select(sel + (k === Qt.Key_J || k === Qt.Key_Down ? 1 : -1));
        } else if ((k === Qt.Key_Return || k === Qt.Key_Enter) && kbd && n)
            Notifs.activate(n);
        else if ((k === Qt.Key_Delete || k === Qt.Key_Backspace) && (e.modifiers & Qt.ShiftModifier))
            Notifs.clearAll();
        else if ((k === Qt.Key_X || k === Qt.Key_Delete || k === Qt.Key_Backspace) && kbd && n)
            n.dismiss();   // 删掉后下标不变，自然落到下一条；最后一条时由 onCountChanged 收回来
        else if (k === Qt.Key_D)
            Notifs.dnd = !Notifs.dnd;
        else if (k === Qt.Key_H || k === Qt.Key_Left)
            shiftMonth(-1);
        else if (k === Qt.Key_L || k === Qt.Key_Right)
            shiftMonth(1);
        else if (k === Qt.Key_Period)
            shiftMonth(0);
        else
            return;
        e.accepted = true;
    }

    // 面板外的点击：关闭
    PanelWindow {
        screen: center.screen
        visible: Notifs.centerOpen
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
            onPressed: Notifs.centerOpen = false
        }
    }

    PanelWindow {
        id: win
        screen: center.screen
        visible: Notifs.centerOpen
        WlrLayershell.namespace: "quickshell-notificationcenter"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore
        // 只锚定顶边：水平居中，正好在时钟下方
        anchors.top: true
        margins.top: 6 + 32 + 8
        implicitWidth: 420
        implicitHeight: content.implicitHeight + 32
        color: "transparent"
        BackgroundEffect.blurRegion: Region { item: bg; radius: 22 }

        onVisibleChanged: if (visible) {
            cal.month = new Date(clock.date.getFullYear(), clock.date.getMonth(), 1);
            center.kbd = false;
            center.sel = 0;
            content.forceActiveFocus();
        }

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

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
                Keys.onPressed: e => center.handleKey(e)

                // ── 月历 ──
                Column {
                    id: cal
                    width: parent.width
                    spacing: 6
                    property date month: new Date(clock.date.getFullYear(), clock.date.getMonth(), 1)

                    // 周一开头的 6×7 格
                    readonly property var days: {
                        const first = new Date(month.getFullYear(), month.getMonth(), 1);
                        const start = new Date(first);
                        start.setDate(1 - (first.getDay() + 6) % 7);
                        const out = [];
                        for (let i = 0; i < 42; i++) {
                            const d = new Date(start);
                            d.setDate(start.getDate() + i);
                            out.push(d);
                        }
                        return out;
                    }

                    Item {
                        width: parent.width
                        height: 32
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            text: Qt.locale("zh_CN").toString(clock.date, "M月d日 dddd")
                            color: "white"
                            font.family: "Adwaita Sans"
                            font.pixelSize: 16
                            font.bold: true
                        }
                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4
                            Repeater {
                                model: [
                                    { icon: "󰅁", delta: -1 },
                                    { label: true, delta: 0 },
                                    { icon: "󰅂", delta: 1 }
                                ]
                                Rectangle {
                                    required property var modelData
                                    width: modelData.label ? monthText.implicitWidth + 20 : 28
                                    height: 28
                                    radius: 14
                                    color: navMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
                                    Text {
                                        id: monthText
                                        anchors.centerIn: parent
                                        text: parent.modelData.label ? Qt.formatDate(cal.month, "yyyy年M月") : parent.modelData.icon
                                        color: "white"
                                        font.family: "Adwaita Sans"
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                    // 左右翻月；点中间回到本月
                                    MouseArea {
                                        id: navMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: center.shiftMonth(parent.modelData.delta)
                                    }
                                }
                            }
                        }
                    }

                    Grid {
                        columns: 7
                        width: parent.width
                        readonly property real cell: width / 7

                        Repeater {
                            model: ["一", "二", "三", "四", "五", "六", "日"]
                            Text {
                                required property string modelData
                                width: parent.cell
                                height: 24
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                text: modelData
                                color: Qt.rgba(1, 1, 1, 0.5)
                                font.family: "Adwaita Sans"
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }
                        Repeater {
                            model: cal.days
                            Item {
                                required property var modelData
                                readonly property bool today: modelData.toDateString() === clock.date.toDateString()
                                readonly property bool inMonth: modelData.getMonth() === cal.month.getMonth()
                                width: parent.cell
                                height: 34
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: parent.today ? center.accent : "transparent"
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData.getDate()
                                    color: parent.today ? "#1e1e2e" : parent.inMonth ? "white" : Qt.rgba(1, 1, 1, 0.3)
                                    font.family: "Adwaita Sans"
                                    font.pixelSize: 13
                                    font.bold: parent.today
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                }

                // ── 通知 ──
                Item {
                    width: parent.width
                    height: 32
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: "通知"
                        color: "white"
                        font.family: "Adwaita Sans"
                        font.pixelSize: 16
                        font.bold: true
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // 勿扰：开关
                        Row {
                            spacing: 8
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "勿扰"
                                color: Qt.rgba(1, 1, 1, 0.8)
                                font.family: "Adwaita Sans"
                                font.pixelSize: 13
                            }
                            Rectangle {
                                width: 40
                                height: 22
                                radius: 11
                                color: Notifs.dnd ? center.accent : Qt.rgba(1, 1, 1, 0.2)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Rectangle {
                                    x: Notifs.dnd ? parent.width - width - 3 : 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: "white"
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Notifs.dnd = !Notifs.dnd
                                }
                            }
                        }

                        Rectangle {
                            visible: Notifs.list.length > 0
                            width: clearText.implicitWidth + 24
                            height: 28
                            radius: 14
                            color: clearMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.1)
                            Text {
                                id: clearText
                                anchors.centerIn: parent
                                text: "全部清除"
                                color: "white"
                                font.family: "Adwaita Sans"
                                font.pixelSize: 13
                                font.bold: true
                            }
                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: Notifs.clearAll()
                            }
                        }
                    }
                }

                // 没有通知
                Text {
                    visible: Notifs.list.length === 0
                    width: parent.width
                    height: 80
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: "󰂚\n没有通知"
                    color: Qt.rgba(1, 1, 1, 0.4)
                    font.family: "Adwaita Sans"
                    font.pixelSize: 14
                    lineHeight: 1.3
                }

                // 通知列表：最高 480，超出滚动；往旁边滑走 = 删除
                // 上下左右留 4px 给焦点框（ListView 会裁掉超出的部分）
                ListView {
                    id: list
                    visible: Notifs.list.length > 0
                    width: parent.width
                    height: Math.min(contentHeight + 8, 480)
                    clip: true
                    spacing: 8
                    topMargin: 4
                    bottomMargin: 4
                    boundsBehavior: Flickable.StopAtBounds
                    model: Notifs.list
                    onCountChanged: if (center.sel >= count)
                        center.sel = Math.max(0, count - 1)
                    delegate: NotificationCard {
                        required property var modelData
                        required property int index
                        notif: modelData
                        x: 4
                        width: list.width - 8
                        focused: center.kbd && center.sel === index
                        onSwiped: modelData.dismiss()
                    }
                }

                Text {
                    visible: center.kbd
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "j k 选择 · Enter 打开 · x 删除 · ⇧Del 全部清除 · d 勿扰 · h l 翻月"
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font.family: "Adwaita Sans"
                    font.pixelSize: 12
                }
            }
        }
    }
}
