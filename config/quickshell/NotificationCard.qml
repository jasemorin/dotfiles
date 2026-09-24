// 一条通知：图标、应用名 · 时间、标题、正文（支持简单 HTML 和链接）、动作按钮、关闭按钮
// 弹窗和通知中心共用。像 macOS 一样可以往旁边滑走：两指横向滑动或按住拖动，超过 30% 宽度松手就飞出去（swiped 信号），
// 否则弹回。由使用方决定滑走的含义（弹窗：收起；通知中心：删除）
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Rectangle {
    id: card

    required property var notif
    property bool popup: false
    signal swiped

    // ── 侧滑 ──
    property real offset: 0
    property bool swiping: false
    transform: Translate { x: card.offset }
    opacity: 1 - Math.min(1, Math.abs(offset) / width) * 0.8
    Behavior on offset {
        enabled: !card.swiping
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    function finishSwipe() {
        swiping = false;
        if (Math.abs(offset) > width * 0.3) {
            offset = offset > 0 ? width + 40 : -(width + 40);
            gone.start();
        } else
            offset = 0;
    }
    // 触控板滚动没有「松手」事件：停止滚动 120ms 就当松手
    Timer {
        id: settle
        interval: 120
        onTriggered: card.finishSwipe()
    }
    Timer {
        id: gone
        interval: 200
        onTriggered: card.swiped()
    }

    readonly property bool hovered: mouse.containsMouse || closeMouse.containsMouse
    readonly property bool critical: notif.urgency === NotificationUrgency.Critical

    implicitHeight: body.implicitHeight + 28
    radius: 18
    color: popup ? Qt.rgba(0.08, 0.08, 0.1, 0.6) : mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.06)
    border.color: critical ? "#ff7b63" : Qt.rgba(1, 1, 1, popup ? 0.08 : 0)
    border.width: 1
    Behavior on color { ColorAnimation { duration: 150 } }

    // 通知图标：通知自带图片 > 应用图标（路径或图标名）> 按 desktop 文件找
    readonly property string iconSource: {
        const n = notif;
        if (n.image)
            return n.image;
        const icon = n.appIcon || (DesktopEntries.byId(n.desktopEntry)?.icon ?? "");
        if (!icon)
            return "";
        return icon.startsWith("/") || icon.includes("://") ? icon : Quickshell.iconPath(icon, true);
    }

    function ago(d) {
        if (!d)
            return "";
        const min = Math.floor((clock.date - d) / 60000);
        return min < 1 ? "刚刚" : min < 60 ? min + " 分钟前" : Qt.formatDateTime(d, "HH:mm");
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        property real pressX: 0
        property bool dragged: false

        onPressed: m => {
            pressX = m.x;
            dragged = false;
        }
        onPositionChanged: m => {
            if (!pressed)
                return;
            const dx = m.x - pressX;
            if (!dragged && Math.abs(dx) < 8)
                return;
            dragged = true;
            card.swiping = true;
            card.offset = dx;
        }
        onReleased: if (dragged) card.finishSwipe()
        onClicked: if (!dragged) Notifs.activate(card.notif)

        // 横向滚动（触控板两指左右滑）：跟着手指走；竖向的交给外面的列表滚动
        onWheel: w => {
            const dx = w.pixelDelta.x !== 0 ? w.pixelDelta.x : w.angleDelta.x / 4;
            const dy = w.pixelDelta.y !== 0 ? w.pixelDelta.y : w.angleDelta.y / 4;
            if (Math.abs(dx) <= Math.abs(dy) || gone.running) {
                w.accepted = false;
                return;
            }
            // 自然滚动时 inverted 为 true，此时数值方向就是手指方向
            card.swiping = true;
            card.offset += w.inverted ? dx : -dx;
            settle.restart();
        }
    }

    Row {
        id: body
        x: 14
        y: 14
        width: parent.width - 28
        spacing: 12

        IconImage {
            id: icon
            visible: card.iconSource !== ""
            source: card.iconSource
            implicitSize: 40
        }

        Column {
            width: parent.width - (icon.visible ? icon.width + parent.spacing : 0)
            spacing: 3

            // 应用名 · 时间
            Text {
                width: parent.width - 24
                elide: Text.ElideRight
                text: [card.notif.appName, card.ago(Notifs.times[card.notif.id])].filter(s => s).join(" · ")
                color: Qt.rgba(1, 1, 1, 0.55)
                font.family: "Adwaita Sans"
                font.pixelSize: 12
            }
            Text {
                width: parent.width
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                text: card.notif.summary
                color: "white"
                font.family: "Adwaita Sans"
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                width: parent.width
                visible: text !== ""
                wrapMode: Text.Wrap
                maximumLineCount: card.popup ? 3 : 6
                elide: Text.ElideRight
                textFormat: Text.StyledText
                text: card.notif.body
                color: Qt.rgba(1, 1, 1, 0.8)
                linkColor: "#b4befe"
                font.family: "Adwaita Sans"
                font.pixelSize: 13
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            // 动作按钮（「default」是点整条通知的动作，不单独显示）
            Row {
                spacing: 6
                topPadding: 6
                visible: actions.count > 0
                Repeater {
                    id: actions
                    model: card.notif.actions.filter(a => a.identifier !== "default")
                    Rectangle {
                        required property var modelData
                        width: label.implicitWidth + 24
                        height: 30
                        radius: 15
                        color: actMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.2) : Qt.rgba(1, 1, 1, 0.1)
                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: modelData.text
                            color: "white"
                            font.family: "Adwaita Sans"
                            font.pixelSize: 13
                            font.bold: true
                        }
                        MouseArea {
                            id: actMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: modelData.invoke()
                        }
                    }
                }
            }
        }
    }

    // 关闭：从历史里删掉
    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10
        width: 22
        height: 22
        radius: 11
        visible: card.hovered
        color: closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(1, 1, 1, 0.12)
        Text {
            anchors.centerIn: parent
            text: "󰅖"
            color: "white"
            font.pixelSize: 13
        }
        MouseArea {
            id: closeMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: card.notif.dismiss()
        }
    }
}
