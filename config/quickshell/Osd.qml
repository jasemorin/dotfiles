// 音量 / 屏幕亮度 / 键盘背光 / 大写锁定提示：变化时在屏幕下方弹出一个模糊胶囊，1.5 秒后消失
// 大写锁定（同时按左右 Shift 切换，见 niri 配置）没有进度条，中间写「大写锁定 开 / 关」
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire

PanelWindow {
    id: osd

    property string kind: "volume"   // volume / brightness / keyboard / capslock
    property bool shown: false
    // 启动时的初始值变化不算
    property bool armed: false

    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    readonly property real value: kind === "volume" ? (audio && !audio.muted ? audio.volume : 0) : kind === "keyboard" ? Keyboard.backlightValue : Brightness.value
    readonly property string icon: kind === "brightness" ? "󰃠" : kind === "keyboard" ? "󰌌" : kind === "capslock" ? "󰪛" : !audio || audio.muted ? "󰝟" : ["󰕿", "󰖀", "󰕾"][Math.min(2, Math.floor(audio.volume * 3))]

    function show(k) {
        if (!armed)
            return;
        kind = k;
        shown = true;
        hide.restart();
    }

    Timer {
        interval: 2000
        running: true
        onTriggered: osd.armed = true
    }
    Timer {
        id: hide
        interval: 1500
        onTriggered: osd.shown = false
    }

    Connections {
        target: osd.audio
        function onVolumeChanged() { osd.show("volume"); }
        function onMutedChanged() { osd.show("volume"); }
    }
    Connections {
        target: Brightness
        function onChangesChanged() { osd.show("brightness"); }
    }
    Connections {
        target: Keyboard
        function onBacklightChangesChanged() { osd.show("keyboard"); }
        function onCapsChangesChanged() { osd.show("capslock"); }
    }

    visible: shown
    WlrLayershell.namespace: "quickshell-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    anchors.bottom: true
    margins.bottom: 80
    implicitWidth: 280
    implicitHeight: 48
    color: "transparent"
    // 不挡鼠标
    mask: Region {}
    BackgroundEffect.blurRegion: Region { item: bg; radius: 24 }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 24
        color: Qt.rgba(0, 0, 0, 0.4)

        Text {
            id: icon
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 24
            text: osd.icon
            color: "white"
            font.pixelSize: 18
        }
        // 大写锁定：文字代替进度条
        Text {
            visible: osd.kind === "capslock"
            anchors.centerIn: parent
            text: "大写锁定  " + (Keyboard.capsLock ? "开" : "关")
            color: "white"
            font.family: "Adwaita Sans"
            font.pixelSize: 14
            font.bold: true
        }
        Rectangle {
            visible: osd.kind !== "capslock"
            anchors.left: icon.right
            anchors.leftMargin: 10
            anchors.right: pct.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 8
            radius: 4
            color: Qt.rgba(1, 1, 1, 0.2)
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, osd.value))
                height: parent.height
                radius: parent.radius
                color: "white"
                Behavior on width { NumberAnimation { duration: 100 } }
            }
        }
        Text {
            id: pct
            visible: osd.kind !== "capslock"
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 36
            horizontalAlignment: Text.AlignRight
            text: Math.round(osd.value * 100)
            color: "white"
            font.family: "Adwaita Sans"
            font.pixelSize: 14
            font.bold: true
        }
    }
}
