// 通知服务（取代 swaync）：接收通知、保存历史、管理弹窗队列、勿扰
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    property bool centerOpen: false
    // 打开通知中心前收到的条数，时钟旁的小圆点用
    property int unread: 0
    onCenterOpenChanged: if (centerOpen) {
        unread = 0;
        // 正在弹出的收起；transient 的（如 niri 的截图提示）不进历史
        for (const n of popups.slice())
            popupExpired(n);
    }

    // 历史（新的在前）和正在弹出的
    readonly property var list: server.trackedNotifications.values.slice().reverse()
    property var popups: []
    // 收到的时间：Notification 本身没有
    property var times: ({})

    function removePopup(n) {
        popups = popups.filter(p => p !== n);
    }
    function clearAll() {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
    }
    // 点通知：执行默认动作（没有就只关掉）
    function activate(n) {
        const def = n.actions.find(a => a.identifier === "default");
        if (def)
            def.invoke();
        else
            n.dismiss();
    }
    // 弹窗停留时间：应用指定的优先，否则普通 6 秒、低优先级 3 秒、紧急不自动消失（和原来 swaync 的设置一样）
    function timeout(n) {
        if (n.urgency === NotificationUrgency.Critical)
            return 0;
        if (n.expireTimeout > 0)
            return n.expireTimeout * 1000;
        return n.urgency === NotificationUrgency.Low ? 3000 : 6000;
    }
    // 弹窗时间到：transient 的通知不进历史
    function popupExpired(n) {
        removePopup(n);
        if (n.transient)
            n.expire();
    }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true

        onNotification: n => {
            n.tracked = true;
            const t = Object.assign({}, root.times);
            t[n.id] = new Date();
            root.times = t;
            n.closed.connect(() => root.removePopup(n));
            if (root.centerOpen)
                return;
            root.unread++;
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.popups = [n].concat(root.popups.filter(p => p.id !== n.id));
        }
    }
}
