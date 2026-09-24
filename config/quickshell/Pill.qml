// 胶囊：半透明圆角底色，悬停变亮；背后的模糊由 shell.qml 的 blurRegion 按胶囊形状申请
import QtQuick

Rectangle {
    id: pill

    default property alias content: row.data
    property int padding: 14
    property alias spacing: row.spacing
    property bool hoverable: true
    signal clicked(var mouse)

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
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => pill.clicked(m)
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 0
    }
}
