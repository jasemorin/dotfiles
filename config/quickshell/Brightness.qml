// 屏幕亮度：监听 sysfs 文件变化（亮度键调用 brightnessctl 写入后会触发），设置时也用 brightnessctl
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Asahi MacBook 的面板背光；brightnessctl --class=backlight 选中的也是它
    readonly property string dir: "/sys/class/backlight/apple-panel-bl"
    property int max: 1
    property int current: 0
    readonly property real value: current / max
    // 每次亮度变化加一，给 OSD 用（第一次读取不算）
    property int changes: 0
    property bool ready: false

    function set(v) {
        const pct = Math.max(1, Math.min(100, Math.round(v * 100)));
        Quickshell.execDetached(["brightnessctl", "--class=backlight", "set", pct + "%"]);
    }

    FileView {
        path: root.dir + "/max_brightness"
        onLoaded: root.max = parseInt(text()) || 1
    }
    FileView {
        id: cur
        path: root.dir + "/brightness"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const v = parseInt(text());
            if (root.ready && v !== root.current)
                root.changes++;
            root.current = v;
            root.ready = true;
        }
    }
}
