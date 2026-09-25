// 键盘焦点框：在控件外面 3px 画一圈 2px 的强调色（和 niri 窗口的 focus-ring 同色同粗细）
// 用法：作为控件的最后一个子项，visible 绑定「键盘焦点在这里」；鼠标操作时面板会把它藏起来
import QtQuick

Rectangle {
    anchors.fill: parent
    anchors.margins: -3
    radius: (parent && parent.radius !== undefined ? parent.radius : 0) + 3
    color: "transparent"
    border.width: 2
    border.color: "#b4befe"
}
