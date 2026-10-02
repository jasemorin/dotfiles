// 快捷设置里展开的蓝牙列表（点蓝牙方块右边的 󰅂，或键盘移到它上面按 Enter）
// 上面是配对过的设备（已连接的在前，带电量），展开时让适配器搜索，下面列出附近有名字的新设备
// 选中后 Enter / 点击：已连接 → 断开；已配对 → 连接；新设备 → 配对，配对成功后设为信任并连接
// 需要输 PIN 的设备（部分键盘）这里配不了：用 bluetoothctl
// 键盘焦点由 QuickSettings.qml 统一管理：这里只提供 focusIds（从上到下）和 activate(id)
import QtQuick
import Quickshell
import Quickshell.Bluetooth

Item {
    id: list

    property bool active: false        // 面板开着且展开的是蓝牙：只在这时搜索
    property string focusedId: ""
    signal rowClicked(string id)

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter !== null && adapter.enabled
    readonly property var paired: Bluetooth.devices.values.filter(d => d.paired || d.connected).sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    // 没有名字的（只有地址）不列出来；最多 5 个，不然面板会比屏幕还高
    readonly property var nearby: active ? Bluetooth.devices.values.filter(d => !d.paired && !d.connected && d.deviceName !== "").sort((a, b) => a.name.localeCompare(b.name)).slice(0, 5) : []
    readonly property var focusIds: paired.concat(nearby).map(d => "dev:" + d.address)
    property string pairingAddress: ""   // 从这里发起配对的设备：配对成功后接着连接

    implicitHeight: col.implicitHeight

    onActiveChanged: updateDiscovery()
    onEnabledChanged: updateDiscovery()
    function updateDiscovery() {
        if (enabled && adapter.discovering !== active)
            adapter.discovering = active;
    }

    function glyph(icon) {
        if (icon.startsWith("audio-headphones") || icon.startsWith("audio-headset"))
            return "󰋋";
        if (icon.startsWith("audio"))
            return "󰓃";
        return ({
                "input-keyboard": "󰌌",
                "input-mouse": "󰍽",
                "input-gaming": "󰊴",
                "input-tablet": "󰓶",
                "phone": "󰏲",
                "computer": "󰌢"
            })[icon] ?? "󰂯";
    }
    function status(d) {
        if (d.pairing)
            return "配对中…";
        if (d.state === BluetoothDeviceState.Connecting)
            return "连接中…";
        if (d.state === BluetoothDeviceState.Disconnecting)
            return "断开中…";
        if (d.connected)
            return d.batteryAvailable ? "已连接 · " + Math.round(d.battery * 100) + "%" : "已连接";
        return "";
    }
    function activate(id) {
        const d = paired.concat(nearby).find(x => "dev:" + x.address === id);
        if (!d || d.pairing || d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting)
            return;
        if (d.connected)
            d.disconnect();
        else if (d.paired)
            d.connect();
        else {
            pairingAddress = d.address;
            d.pair();
        }
    }

    component Header: Text {
        leftPadding: 10
        color: Qt.rgba(1, 1, 1, 0.6)
        font.family: "Adwaita Sans"
        font.pixelSize: 12
    }

    component DeviceEntry: DeviceRow {
        id: entry
        required property var modelData
        x: 4
        width: col.width - 8
        icon: list.glyph(modelData.icon)
        title: modelData.name
        active: modelData.connected
        status: list.status(modelData)
        focused: list.focusedId === "dev:" + modelData.address
        onClicked: list.rowClicked("dev:" + modelData.address)

        Connections {
            target: entry.modelData
            function onPairedChanged() {
                if (entry.modelData.paired && list.pairingAddress === entry.modelData.address) {
                    list.pairingAddress = "";
                    entry.modelData.trusted = true;   // 以后开机自动重连
                    entry.modelData.connect();
                }
            }
        }
    }

    Column {
        id: col
        width: parent.width
        spacing: 6
        topPadding: 3
        bottomPadding: 3

        Header {
            visible: !list.enabled || list.paired.length > 0
            text: list.enabled ? "我的设备" : "蓝牙已关闭"
        }
        Repeater {
            model: list.enabled ? list.paired : []
            DeviceEntry {}
        }

        Header {
            visible: list.enabled
            text: list.adapter && list.adapter.discovering ? "附近的设备（正在搜索…）" : "附近的设备"
        }
        Repeater {
            model: list.enabled ? list.nearby : []
            DeviceEntry {}
        }
    }
}
