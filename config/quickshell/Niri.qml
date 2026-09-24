// niri 状态：监听事件流，有变化就重新查一次工作区和当前窗口
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var workspaces: []
    property string windowTitle: ""

    function focusWorkspace(idx) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(idx)]);
    }

    Process {
        id: events
        running: true
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: refresh.restart()
        }
        // niri 重启等情况下断开后自动重连
        onRunningChanged: if (!running) reconnect.start()
    }
    Timer {
        id: reconnect
        interval: 1000
        onTriggered: events.running = true
    }
    Timer {
        id: refresh
        interval: 30
        onTriggered: {
            wsQuery.running = true;
            winQuery.running = true;
        }
    }
    Process {
        id: wsQuery
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: root.workspaces = JSON.parse(text).sort((a, b) => a.idx - b.idx)
        }
    }
    Process {
        id: winQuery
        command: ["niri", "msg", "--json", "focused-window"]
        stdout: StdioCollector {
            onStreamFinished: {
                const w = JSON.parse(text);
                root.windowTitle = w && w.title ? w.title : "";
            }
        }
    }
}
