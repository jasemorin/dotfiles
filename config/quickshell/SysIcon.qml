// 系统图标组里的单个图标：各自有悬停提示和点击
import QtQuick

Label {
    id: icon

    property string tooltip: ""
    signal clicked(var mouse)

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => icon.clicked(m)
    }

    Tooltip {
        target: icon
        text: icon.tooltip
        hovered: mouse.containsMouse
    }
}
