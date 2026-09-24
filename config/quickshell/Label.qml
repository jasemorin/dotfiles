// 顶栏文字：Adwaita Sans 粗体白字，和 GNOME 顶栏一致；图标字形由 fontconfig 回退到 Symbols Nerd Font
import QtQuick

Text {
    color: "white"
    font.family: "Adwaita Sans"
    font.pixelSize: 14
    font.bold: true
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
}
