// 悬停提示：停留 400ms 后在目标下方弹出，背后模糊
import QtQuick
import Quickshell
import Quickshell.Wayland

PopupWindow {
    id: tip

    required property Item target
    property string text: ""
    property bool hovered: false

    anchor.item: target
    anchor.rect.width: target.width
    anchor.rect.height: target.height + 8
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    visible: shown && text !== ""
    property bool shown: false
    onHoveredChanged: hovered ? delay.restart() : (delay.stop(), shown = false)

    Timer {
        id: delay
        interval: 400
        onTriggered: tip.shown = true
    }

    implicitWidth: label.implicitWidth + 24
    implicitHeight: label.implicitHeight + 14
    color: "transparent"
    BackgroundEffect.blurRegion: Region { item: bg; radius: 10 }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 10
        color: Qt.rgba(0.12, 0.12, 0.12, 0.8)

        Text {
            id: label
            anchors.centerIn: parent
            text: tip.text
            color: "white"
            font.family: "Adwaita Sans"
            font.pixelSize: 14
        }
    }
}
