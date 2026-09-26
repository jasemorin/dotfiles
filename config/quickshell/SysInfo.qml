// 内存、网速（读 /proc）和网络状态（Quickshell.Networking，NetworkManager 有变化时自己推送）
// 不起进程：/proc 文件用 FileView 定时重读；以前每 2 / 5 秒起一次 cat，每 5 秒起一个 sh + 三次 nmcli
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

Singleton {
    id: root

    property int memPercent: 0
    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property string netUp: "0.0B/s"
    property string netDown: "0.0B/s"
    property var lastNet: null

    // ── 网络状态 ──
    readonly property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNetwork: wifiDevice ? wifiDevice.networks.values.find(n => n.connected) ?? null : null
    readonly property bool wiredConnected: Networking.devices.values.some(d => d.type === DeviceType.Wired && d.connected)
    readonly property string netState: wifiNetwork ? "wifi" : wiredConnected ? "ethernet" : "none"   // wifi / ethernet / none
    readonly property int wifiSignal: wifiNetwork ? Math.round(wifiNetwork.signalStrength * 100) : 0
    readonly property string wifiSsid: wifiNetwork ? wifiNetwork.name : ""
    readonly property bool wifiEnabled: Networking.wifiEnabled

    function setWifi(on) {
        Networking.wifiEnabled = on;
    }

    // 和 waybar 的 {bandwidthUpBytes} 一样：1000 进制，一位小数
    function speed(bytes) {
        const units = ["B", "kB", "MB", "GB"];
        let i = 0;
        while (bytes >= 1000 && i < units.length - 1) {
            bytes /= 1000;
            i++;
        }
        return bytes.toFixed(1) + units[i] + "/s";
    }

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        blockLoading: true
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            meminfo.reload();
            const text = meminfo.text();
            const get = k => parseInt((text.match(new RegExp("^" + k + ":\\s+(\\d+)", "m")) || [0, 0])[1]);
            const total = get("MemTotal");
            if (!total)
                return;
            const used = total - get("MemAvailable");
            root.memPercent = Math.round(used / total * 100);
            root.memUsedGiB = used / 1048576;
            root.memTotalGiB = total / 1048576;
        }
    }

    FileView {
        id: netdev
        path: "/proc/net/dev"
        blockLoading: true
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            netdev.reload();
            let rx = 0, tx = 0;
            for (const line of netdev.text().split("\n").slice(2)) {
                const f = line.trim().split(/[:\s]+/);
                if (f.length < 10 || f[0] === "lo")
                    continue;
                rx += Number(f[1]);
                tx += Number(f[9]);
            }
            const now = Date.now();
            if (root.lastNet) {
                const dt = (now - root.lastNet.t) / 1000;
                root.netDown = root.speed(Math.max(0, rx - root.lastNet.rx) / dt);
                root.netUp = root.speed(Math.max(0, tx - root.lastNet.tx) / dt);
            }
            root.lastNet = { t: now, rx: rx, tx: tx };
        }
    }
}
