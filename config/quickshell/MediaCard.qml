// 快捷设置里的「正在播放」卡片：封面、歌名 / 歌手、进度、上一首 / 播放暂停 / 下一首
// 有可控制的播放器（MPRIS：Spotify、Firefox 里的视频、mpv…）时才出现；播放器选法和顶栏的媒体胶囊一样：
// 优先正在播放的，其次任意能控制的
// 键盘焦点由 QuickSettings.qml 统一管理：这里只提供 focusIds 和 activate(id)
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

Rectangle {
    id: card

    property string focusedId: ""
    signal buttonClicked(string id)

    readonly property var player: {
        const ps = Mpris.players.values;
        return ps.find(p => p.isPlaying) ?? ps.find(p => p.canControl) ?? null;
    }
    readonly property var focusIds: player ? ["media:prev", "media:play", "media:next"] : []

    function activate(id) {
        if (!player)
            return;
        if (id === "media:prev" && player.canGoPrevious)
            player.previous();
        else if (id === "media:play" && player.canTogglePlaying)
            player.togglePlaying();
        else if (id === "media:next" && player.canGoNext)
            player.next();
    }
    function time(s) {
        s = Math.max(0, Math.floor(s));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    visible: player !== null
    implicitHeight: visible ? 116 : 0
    radius: 18
    color: Qt.rgba(1, 1, 1, 0.1)

    // position 不会自己一直更新：播放时每秒让它刷新一次
    Timer {
        interval: 1000
        repeat: true
        running: card.visible && card.player !== null && card.player.isPlaying
        onTriggered: card.player.positionChanged()
    }

    // 封面：没有就显示一个音符
    Rectangle {
        id: art
        x: 12
        y: 12
        width: 56
        height: 56
        radius: 12
        color: Qt.rgba(1, 1, 1, 0.1)
        clip: true

        Text {
            anchors.centerIn: parent
            visible: cover.status !== Image.Ready
            text: "󰝚"
            color: Qt.rgba(1, 1, 1, 0.6)
            font.pixelSize: 24
        }
        ClippingRectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            Image {
                id: cover
                anchors.fill: parent
                source: card.player ? card.player.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 112
                sourceSize.height: 112
            }
        }
    }

    Column {
        anchors.left: art.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        y: 14
        spacing: 2

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: card.player ? (card.player.trackTitle || card.player.identity) : ""
            color: "white"
            font.family: "Adwaita Sans"
            font.pixelSize: 14
            font.bold: true
        }
        Text {
            width: parent.width
            elide: Text.ElideRight
            visible: text !== ""
            text: card.player ? [card.player.trackArtist, card.player.identity].filter(s => s).join(" · ") : ""
            color: Qt.rgba(1, 1, 1, 0.6)
            font.family: "Adwaita Sans"
            font.pixelSize: 12
        }
    }

    // 按钮：在封面右边、文字下面
    Row {
        id: buttons
        anchors.left: art.right
        anchors.leftMargin: 6
        y: 50
        spacing: 4

        Repeater {
            model: [
                { id: "media:prev", icon: "󰒮" },
                { id: "media:play", icon: "" },
                { id: "media:next", icon: "󰒭" }
            ]
            Rectangle {
                id: button
                required property var modelData
                width: 30
                height: 30
                radius: 15
                color: buttonMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: button.modelData.id === "media:play" ? (card.player && card.player.isPlaying ? "󰏤" : "󰐊") : button.modelData.icon
                    color: "white"
                    font.pixelSize: 18
                }
                MouseArea {
                    id: buttonMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: card.buttonClicked(button.modelData.id)
                }
                FocusRing {
                    visible: card.focusedId === button.modelData.id
                }
            }
        }
    }

    // 进度：时间 + 细条
    Item {
        visible: card.player !== null && card.player.lengthSupported && card.player.length > 0
        x: 12
        y: 84
        width: parent.width - 24
        height: 20

        Text {
            id: posText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: card.player ? card.time(card.player.position) : ""
            color: Qt.rgba(1, 1, 1, 0.6)
            font.family: "Adwaita Sans"
            font.pixelSize: 11
        }
        Rectangle {
            anchors.left: posText.right
            anchors.leftMargin: 8
            anchors.right: lenText.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: 4
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.15)
            Rectangle {
                width: card.player && card.player.length > 0 ? parent.width * Math.min(1, card.player.position / card.player.length) : 0
                height: parent.height
                radius: parent.radius
                color: "white"
            }
        }
        Text {
            id: lenText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: card.player ? card.time(card.player.length) : ""
            color: Qt.rgba(1, 1, 1, 0.6)
            font.family: "Adwaita Sans"
            font.pixelSize: 11
        }
    }
}
