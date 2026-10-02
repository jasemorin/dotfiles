// 快捷设置里 Wi-Fi / 蓝牙列表的一行：左边图标和名字，右边灰色的状态和小图标；已连接的一行用强调色
import QtQuick

Rectangle {
    id: row

    property string icon
    property string title
    property string status          // 右边的灰字：已连接 / 已保存 / 连接中… / 80%
    property string trailingIcon    // 最右边的小图标，比如加密网络的锁
    property bool active            // 已连接
    property bool focused           // 键盘焦点在这一行
    signal clicked(var mouse)

    implicitHeight: 38
    radius: 12
    color: rowMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : "transparent"
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: iconText
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        text: row.icon
        color: row.active ? "#b4befe" : "white"
        font.pixelSize: 16
    }

    Text {
        anchors.left: iconText.right
        anchors.leftMargin: 8
        anchors.right: trailing.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: row.title
        color: row.active ? "#b4befe" : "white"
        font.family: "Adwaita Sans"
        font.pixelSize: 13
        font.bold: row.active
    }

    Row {
        id: trailing
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Text {
            visible: text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: row.status
            color: Qt.rgba(1, 1, 1, 0.6)
            font.family: "Adwaita Sans"
            font.pixelSize: 12
        }
        Text {
            visible: text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: row.trailingIcon
            color: Qt.rgba(1, 1, 1, 0.6)
            font.pixelSize: 12
        }
    }

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => row.clicked(m)
    }

    FocusRing {
        visible: row.focused
    }
}
