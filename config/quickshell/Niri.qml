// niri 状态：直接解析 niri msg --json event-stream 的事件
// 连上时 niri 会先发完整的 WorkspacesChanged / WindowsChanged，之后只发增量；
// 以前每来一个事件就起两个 niri msg 进程重新查一遍，窗口标题一变（终端里的动画）就是一堆进程
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var workspaces: []
    property var windows: ({})        // id → niri 的窗口对象
    property var focusedWindow: null  // 当前窗口的 id
    readonly property string windowTitle: {
        const w = focusedWindow !== null ? windows[focusedWindow] : null;
        return w && w.title ? w.title : "";
    }

    function focusWorkspace(idx) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(idx)]);
    }

    function handle(ev) {
        if (ev.WorkspacesChanged) {
            workspaces = ev.WorkspacesChanged.workspaces.slice().sort((a, b) => a.idx - b.idx);
        } else if (ev.WorkspaceActivated) {
            const id = ev.WorkspaceActivated.id, focused = ev.WorkspaceActivated.focused;
            const target = workspaces.find(w => w.id === id);
            if (!target)
                return;
            // 同一个屏幕上只有一个 active；focused 时它也成为全局唯一的 focused
            workspaces = workspaces.map(w => Object.assign({}, w, {
                    is_active: w.output === target.output ? w.id === id : w.is_active,
                    is_focused: focused ? w.id === id : w.is_focused
                }));
        } else if (ev.WindowsChanged) {
            const m = {};
            for (const w of ev.WindowsChanged.windows) {
                m[w.id] = w;
                if (w.is_focused)
                    focusedWindow = w.id;
            }
            windows = m;
        } else if (ev.WindowOpenedOrChanged) {
            const w = ev.WindowOpenedOrChanged.window;
            const m = Object.assign({}, windows);
            m[w.id] = w;
            windows = m;
            if (w.is_focused)
                focusedWindow = w.id;
        } else if (ev.WindowClosed) {
            const m = Object.assign({}, windows);
            delete m[ev.WindowClosed.id];
            windows = m;
            if (focusedWindow === ev.WindowClosed.id)
                focusedWindow = null;
        } else if (ev.WindowFocusChanged) {
            focusedWindow = ev.WindowFocusChanged.id;
        }
    }

    Process {
        id: events
        running: true
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    root.handle(JSON.parse(line));
                } catch (e) {
                    console.warn("niri event parse failed:", e);
                }
            }
        }
        // niri 重启等情况下断开后自动重连（重连时又会先收到完整状态）
        onRunningChanged: if (!running)
            reconnect.start()
    }
    Timer {
        id: reconnect
        interval: 1000
        onTriggered: events.running = true
    }
}
