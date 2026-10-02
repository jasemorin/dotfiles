// 通知弹窗：顶栏下方右侧往下叠，鼠标悬停时暂停倒计时；点击执行默认动作，× 删除
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    visible: Notifs.popups.length > 0
    WlrLayershell.namespace: "quickshell-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        right: true
    }
    margins {
        top: 6 + 32 + 8
        right: 10
    }
    implicitWidth: 380
    implicitHeight: Math.max(1, stack.implicitHeight)
    color: "transparent"

    // 每张卡片各自一块圆角模糊区域（卡片之间的空隙不模糊）；卡片增减时重建
    BackgroundEffect.blurRegion: Region {
        id: blur
    }
    Component {
        id: regionComp
        Region {
            radius: 18
        }
    }
    function rebuildBlur() {
        const old = blur.regions;
        const regions = [];
        for (let i = 0; i < cards.count; i++) {
            const c = cards.itemAt(i);
            if (c)
                regions.push(regionComp.createObject(blur, { item: c }));
        }
        blur.regions = regions;
        for (const r of old)
            r.destroy();
    }

    Column {
        id: stack
        width: parent.width
        spacing: 8

        Repeater {
            id: cards
            model: Notifs.popups
            onItemAdded: Qt.callLater(win.rebuildBlur)
            onItemRemoved: Qt.callLater(win.rebuildBlur)

            NotificationCard {
                id: card
                required property var modelData
                notif: modelData
                popup: true
                width: stack.width
                // 滑走 = 收起弹窗，通知还留在通知中心（和 macOS 一样）
                onSwiped: Notifs.popupExpired(card.notif)

                Timer {
                    interval: Notifs.timeout(card.notif)
                    running: interval > 0 && !card.hovered && !card.swiping
                    onTriggered: Notifs.popupExpired(card.notif)
                }
            }
        }
    }
}
