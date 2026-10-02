// 低电量提醒：放电时降到 20% / 10% / 5% 各发一条通知（10% 起是紧急通知，不会自动消失、勿扰时也弹）；
// 接上电源后重置，下次放电重新提醒。通知走 notify-send，由 Notifs.qml 自己接收显示
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Scope {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property int pct: Math.round(dev.percentage * 100)
    readonly property bool discharging: dev.state === UPowerDeviceState.Discharging
    // 这次放电已经提醒过的最低档位（101 = 还没提醒过）
    property int warned: 101

    // 该提醒的档位：低于某档且这档还没提醒过；没有就返回 0
    function levelToWarn(pct, warned) {
        const level = [5, 10, 20].find(t => pct <= t);
        return level !== undefined && level < warned ? level : 0;
    }

    function check() {
        if (!dev.ready || !dev.isLaptopBattery)
            return;
        if (!discharging) {
            warned = 101;
            return;
        }
        const level = levelToWarn(pct, warned);
        if (!level)
            return;
        warned = level;
        const left = dev.timeToEmpty > 0 ? "，大约还能用 " + Math.round(dev.timeToEmpty / 60) + " 分钟" : "";
        Quickshell.execDetached(["notify-send", "-a", "电池", "-i", level <= 5 ? "battery-empty-symbolic" : "battery-caution-symbolic", "-u", level <= 10 ? "critical" : "normal", "电量低：" + pct + "%", "请接上电源" + left]);
    }

    onPctChanged: check()
    onDischargingChanged: check()
    Component.onCompleted: check()
    Connections {
        target: root.dev
        function onReadyChanged() { root.check(); }
    }
}
