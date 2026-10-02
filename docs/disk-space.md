# 给 Linux 扩容（从 macOS 让出空间）

来源：Asahi Linux 分区说明（Partitioning cheatsheet）。先在 macOS 里缩小 macOS，再在 Linux 里把空出的空间**加进** btrfs。
Linux 分区没法直接拉大：空出来的空间不挨着它（中间隔着 Asahi 启动 stub、EFI、/boot）。

## 1. macOS 里（先备份）

```bash
diskutil list                                # 找 macOS 的 APFS 容器（最大那个，通常 disk0s2）
diskutil apfs resizeContainer disk0s2 300g   # 缩到 300 GB（自己定）
```

不要动其他 APFS 分区（Asahi 启动 stub、恢复分区）。

## 2. Linux 里

```bash
sudo cfdisk /dev/nvme0n1          # 在空闲空间新建分区，类型 Linux filesystem，写入退出
lsblk                             # 记下新分区名，比如 nvme0n1p8
sudo btrfs device add /dev/nvme0n1p8 /
sudo btrfs filesystem usage /     # 确认容量变大
```

之后 / 和 /home 直接可用新空间，不用重启。btrfs 变成跨两个分区，但都在同一块 SSD 上，风险不变。
