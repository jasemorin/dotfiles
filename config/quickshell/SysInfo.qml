// 内存、网速（读 /proc）和网络状态（nmcli）
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int memPercent: 0
    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property string netUp: "0.0B/s"
    property string netDown: "0.0B/s"
    property var lastNet: null

    property string netState: "none"   // wifi / ethernet / none
    property int wifiSignal: 0
    property string wifiSsid: ""
    property bool wifiEnabled: true

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

    function setWifi(on) {
        root.wifiEnabled = on;
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
        nmTimer.restart();
    }

    Process {
        id: memQuery
        command: ["cat", "/proc/meminfo"]
        stdout: StdioCollector {
            onStreamFinished: {
                const get = k => parseInt(text.match(new RegExp("^" + k + ":\\s+(\\d+)", "m"))[1]);
                const total = get("MemTotal");
                const used = total - get("MemAvailable");
                root.memPercent = Math.round(used / total * 100);
                root.memUsedGiB = used / 1048576;
                root.memTotalGiB = total / 1048576;
            }
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: memQuery.running = true
    }

    Process {
        id: netQuery
        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                let rx = 0, tx = 0;
                for (const line of text.split("\n").slice(2)) {
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
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: netQuery.running = true
    }

    // 第一行：Wi-Fi 开关；第二行：当前 Wi-Fi「信号:名称」；第三行：已连接的有线网卡数
    Process {
        id: nmQuery
        command: ["sh", "-c", "nmcli radio wifi; nmcli -t -f IN-USE,SIGNAL,SSID dev wifi list --rescan no | sed -n 's/^\\*://p' | head -1; nmcli -t -f TYPE,STATE dev | grep -c '^ethernet:connected$'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                root.wifiEnabled = lines[0].trim() === "enabled";
                const m = lines[1].match(/^(\d+):(.*)$/);
                if (m) {
                    root.netState = "wifi";
                    root.wifiSignal = parseInt(m[1]);
                    root.wifiSsid = m[2].replace(/\\:/g, ":");
                } else {
                    root.netState = parseInt(lines[2]) > 0 ? "ethernet" : "none";
                    root.wifiSsid = "";
                }
            }
        }
    }
    Timer {
        id: nmTimer
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: nmQuery.running = true
    }
}
