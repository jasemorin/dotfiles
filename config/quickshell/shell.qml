//@ pragma IconTheme Adwaita
//@ pragma UseQApplication
// 托盘图标的右键菜单（platform menu）需要 QApplication
// niri 下没有桌面环境告诉 Qt 用哪个图标主题（GNOME 下是 Adwaita），不指定的话 fcitx 的托盘图标加载不出来
// 顶栏 + 快捷设置面板 + 音量/亮度提示（取代 waybar）
// 胶囊、面板、提示背后都单独模糊：用 BackgroundEffect.blurRegion 把形状告诉 niri（ext-background-effect）。
// waybar 做不到这点：niri 只能模糊整条栏的矩形，胶囊之间会有一条磨砂横带。
// 需要 Quickshell ≥ 0.3（COPR errornointernet/quickshell）；在 niri 下由 niri/config.kdl 启动
//
// Bar.qml          顶栏（胶囊、悬停提示、媒体）
// QuickSettings.qml 点系统图标打开的面板
// Osd.qml          音量 / 亮度提示
// Niri / SysInfo / Brightness.qml  状态单例
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

ShellRoot {
    // 音量：要跟踪默认输出设备，才能读到 volume / muted
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Osd {}
}
