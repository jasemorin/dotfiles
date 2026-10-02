// 快捷设置里的开关和电源菜单的状态（单例）
// 保持唤醒：Bar.qml 里每块屏一个 IdleInhibitor，开着时 swayidle 不会锁屏、关屏（niri 支持 idle-inhibit 协议）
// 夜间模式：quickshell 带着一个 wlsunset 子进程，色温固定 4000K（-t 和 -T 只差 1K，所以不随日出日落变化）；
//   关掉开关或 quickshell 退出时 wlsunset 也跟着退出，屏幕色温恢复
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool keepAwake: false
    property bool nightLight: false
    property bool sessionMenu: false
    // 没装 wlsunset 时夜间模式的方块显示「未安装」，点了没反应
    property bool nightLightAvailable: false

    onNightLightChanged: sunset.running = nightLight && nightLightAvailable

    Process {
        running: true
        command: ["sh", "-c", "command -v wlsunset"]
        onExited: code => root.nightLightAvailable = code === 0
    }

    Process {
        id: sunset
        command: ["wlsunset", "-t", "4000", "-T", "4001"]
        // 自己退出了（比如被别的调色温程序顶掉）：开关跟着关
        onRunningChanged: if (!running)
            root.nightLight = false
    }
}
