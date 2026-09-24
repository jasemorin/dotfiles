// 胶囊：半透明圆角底色，悬停变亮；背后的模糊由 Bar.qml 的 blurRegion 按胶囊形状申请
import QtQuick

Rectangle {
    id: pill

    default property alias content: row.data
    property int padding: 14
    property alias spacing: row.spacing
    property bool hoverable: true
    property string tooltip: ""
    readonly property bool hovered: mouse.containsMouse
    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: 32
    radius: height / 2
    color: Qt.rgba(0, 0, 0, 0.35)

    // 悬停高亮叠在底色上，和 GNOME 顶栏一样
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(1, 1, 1, 0.15)
        opacity: pill.hoverable && mouse.containsMouse ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: m => pill.clicked(m)
        onWheel: w => pill.wheel(w)
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0
    }

    Tooltip {
        target: pill
        text: pill.tooltip
        hovered: mouse.containsMouse
    }
}
