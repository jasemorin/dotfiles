// 电源菜单：cmd+shift+Q、快捷设置面板右上角的电源键，或 qs ipc call session toggle 打开
// 全屏模糊遮罩 + 一排大按钮：锁屏 / 睡眠 / 注销 / 重启 / 关机 / 重启进 macOS
// ← → / h l / Tab 选择，Enter 或空格确认，Esc 或点空白处取消。
// 故意没有单键直达：误按一个键就关机太危险，选中再确认只多按一下
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: menu

    readonly property bool open: Toggles.sessionMenu
    property int current: 0
    readonly property color accent: "#b4befe"   // 和 niri 的 focus-ring 同色

    readonly property var actions: [
        { icon: "󰌾", name: "锁屏", cmd: ["swaylock", "-f"] },
        // 睡眠前 swayidle 会先锁屏（before-sleep）
        { icon: "󰤄", name: "睡眠", cmd: ["systemctl", "suspend"] },
        { icon: "󰍃", name: "注销", cmd: ["niri", "msg", "action", "quit", "--skip-confirmation"] },
        { icon: "󰜉", name: "重启", cmd: ["systemctl", "reboot"] },
        { icon: "󰐥", name: "关机", cmd: ["systemctl", "poweroff"] },
        // 只下一次重启进 macOS，会弹密码框（scripts/reboot-macos.sh）
        { icon: "󰀵", name: "macOS", cmd: [Quickshell.env("HOME") + "/.local/bin/reboot-macos"] }
    ]

    function run(i) {
        Toggles.sessionMenu = false;
        Quickshell.execDetached(actions[i].cmd);
    }

    onOpenChanged: if (open)
        current = 0

    // 关闭时等淡出动画结束再隐藏
    visible: open || fade.opacity > 0
    WlrLayershell.namespace: "quickshell-session"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    BackgroundEffect.blurRegion: Region { item: fade }

    IpcHandler {
        target: "session"
        function toggle(): void { Toggles.sessionMenu = !Toggles.sessionMenu; }
    }

    Rectangle {
        id: fade
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        opacity: menu.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        focus: true
        Keys.onPressed: e => {
            const n = menu.actions.length;
            if (e.key === Qt.Key_Escape)
                Toggles.sessionMenu = false;
            else if (e.key === Qt.Key_Left || e.key === Qt.Key_H || e.key === Qt.Key_Backtab)
                menu.current = (menu.current + n - 1) % n;
            else if (e.key === Qt.Key_Right || e.key === Qt.Key_L || e.key === Qt.Key_Tab)
                menu.current = (menu.current + 1) % n;
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space)
                menu.run(menu.current);
            else
                return;
            e.accepted = true;
        }

        // 点按钮以外的地方：取消
        MouseArea {
            anchors.fill: parent
            onClicked: Toggles.sessionMenu = false
        }

        Row {
            id: buttons
            anchors.centerIn: parent
            spacing: 20
            scale: menu.open ? 1 : 0.94
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Repeater {
                model: menu.actions

                Rectangle {
                    id: btn
                    required property var modelData
                    required property int index
                    readonly property bool selected: menu.current === index

                    width: 120
                    height: 120
                    radius: 30
                    color: selected ? menu.accent : Qt.rgba(1, 1, 1, 0.1)
                    border.color: Qt.rgba(1, 1, 1, selected ? 0 : 0.08)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Column {
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: btn.modelData.icon
                            color: btn.selected ? "#1e1e2e" : "white"
                            font.pixelSize: 40
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: btn.modelData.name
                            color: btn.selected ? "#1e1e2e" : "white"
                            font.family: "Adwaita Sans"
                            font.pixelSize: 15
                            font.bold: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: menu.current = btn.index
                        onClicked: menu.run(btn.index)
                    }
                }
            }
        }

        Text {
            anchors.top: buttons.bottom
            anchors.topMargin: 28
            anchors.horizontalCenter: parent.horizontalCenter
            text: "← →  选择　·　Enter  确认　·　Esc  取消"
            color: Qt.rgba(1, 1, 1, 0.6)
            font.family: "Adwaita Sans"
            font.pixelSize: 13
        }
    }
}
