// 键盘背光和大写锁定（单例），给 Osd.qml 用
// 背光：/sys/class/leds/kbd_backlight，Touch Bar 的背光键调用 brightnessctl 写入后文件变化会触发
// 大写锁定：LED 由内核改，不会触发文件变化通知，所以每 0.3 秒读一次（很小的 sysfs 文件）；
//   看所有键盘的 capslock LED（内置键盘和 keyd 的虚拟键盘），任意一个亮就算开
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int backlightMax: 1
    property int backlight: 0
    readonly property real backlightValue: backlight / backlightMax
    // 每次变化加一，给 OSD 用（启动时第一次读取不算）
    property int backlightChanges: 0
    property bool backlightReady: false

    property bool capsLock: false
    property int capsChanges: 0
    property bool capsReady: false

    FileView {
        path: "/sys/class/leds/kbd_backlight/max_brightness"
        onLoaded: root.backlightMax = parseInt(text()) || 1
    }
    FileView {
        path: "/sys/class/leds/kbd_backlight/brightness"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const v = parseInt(text());
            if (root.backlightReady && v !== root.backlight)
                root.backlightChanges++;
            root.backlight = v;
            root.backlightReady = true;
        }
    }

    // 启动时找一次有哪些 capslock LED（inputN 的编号每次开机可能不同），之后只重读文件，不再起进程
    property var capsPaths: []
    Process {
        running: true
        command: ["sh", "-c", "ls -d /sys/class/leds/*::capslock"]
        stdout: StdioCollector {
            onStreamFinished: root.capsPaths = text.split("\n").filter(p => p !== "").map(p => p + "/brightness")
        }
    }
    Instantiator {
        id: capsFiles
        model: root.capsPaths
        FileView {
            required property string modelData
            path: modelData
            blockLoading: true   // reload() 之后马上 text() 要拿到新值
        }
    }
    Timer {
        interval: 300
        running: root.capsPaths.length > 0
        repeat: true
        onTriggered: {
            let on = false;
            for (let i = 0; i < capsFiles.count; i++) {
                const f = capsFiles.objectAt(i);
                f.reload();
                if (parseInt(f.text()) > 0)
                    on = true;
            }
            if (root.capsReady && on !== root.capsLock)
                root.capsChanges++;
            root.capsLock = on;
            root.capsReady = true;
        }
    }
}
