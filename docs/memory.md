# 内存管理（8 GB 的 MacBook Pro M2）

## 现在的机制

- **zswap + 交换文件**：内存紧张时，页面先在内存里压缩（zswap），放不下才写到 SSD 上的
  `/var/swap/swapfile` 和 `swapfile2`（各 8 GB，共 16 GB）。原来只有 8 GB：2026-09-25 开着 Steam、Firefox、Chromium 时
  被用光，Firefox、Chromium、Steam 接连被内核 OOM 结束（`journalctl -k | grep "Out of memory"`）。
  多出的 8 GB 让内存不够时变慢而不是直接结束程序；`restore.sh` 会自动建。Asahi 故意用这套而不是 zram（`/etc/systemd/zram-generator.conf` 关掉了 zram），
  两套压缩叠在一起会互相干扰，**不要再加 zram**。
- **压缩算法**：已从默认的 lzo 改成 zstd，同样的内存能多装约三成（`system/zswap/zswap-zstd.conf`）。
- **电源模式**：`balanced`（swappiness 60）。不要用 `throughput-performance`：它把 swappiness 设成 10，
  内存紧时系统先丢文件缓存而不是把闲置页面压进 zswap，更容易卡，而且 CPU 一直高频更费电。
  如果在 GNOME 电源菜单里选过「性能」，会被切成这个模式。
- **systemd-oomd**：内存和交换都快满时，会结束占用最多的那组进程。
- **MGLRU**（`system/mglru/mglru.conf`）：完整启用内核的新内存回收机制。`min_ttl_ms` 设为 **0**（关闭）：
  原来的 1000（最近 1 秒用过的页面留不住就直接 OOM）不看交换空间，2026-09-25 玩 Big Walk 时交换还剩 13 GB，
  整个 Steam 虚拟机却在加载阶段两次被结束（内核日志 `kswapd0 invoked oom-killer` + `Free swap` 很大就是它）。
  防卡死改由 systemd-oomd 负责。

## 最大的内存大户

- **Steam**：只开客户端就占 3.6–3.9 GB（见 [gaming.md](gaming.md)），不玩时一定要退出。
  `steam-arm64` 把它的虚拟机限制在 3.5 GB：否则下载游戏时虚拟机把文件缓存在自己的内存里，涨到 4 GB 以上且不释放
- **Firefox**：见下
- **Claude Code**：约 0.6–2 GB，`claude daemon stop --any` 可以全部停掉（对话可用 `claude --resume` 继续）

## Firefox

曾经一个 Firefox 占到约 7 GB（2 GB 内存 + 5 GB 交换）。已做的设置：

- `~/.config/mozilla/firefox/<配置>/user.js`（**不在 dotfiles 里**，换机器要重新建）：
  - `browser.tabs.unloadOnLowMemory = true`：内存紧张时自动卸载很久没看的标签页
  - `dom.ipc.processCount = 4`（默认 8）：只限制不隔离的网页进程。开着站点隔离（Fission，进程名 `Isolated Web Co`）时每个网站有自己的进程、不受它限制，所以效果很小（约 0–200 MB）
- 装了 uBlock Origin：屏蔽广告和追踪脚本

## niri 会话里不跑的 GNOME 后台服务

- `config/autostart/org.gnome.Evolution-alarm-notify.desktop`：niri 下不启动日历提醒。
  系统里这一项没有 `OnlyShowIn`，会连带拉起 evolution-source-registry / calendar-factory / addressbook-factory
- 其他 GNOME 自启动项（localsearch 文件索引、gsd-*、gnome-keyring 等）自带 `OnlyShowIn=GNOME`，niri 下本来就不启动
- 系统服务：`~/optimise-memory.sh` 逐项询问后关掉 ModemManager、ABRT、cups、avahi、atd、rsyslog，
  可选去掉 GDM（tty1 登录直接进 niri）；撤销命令在 `~/optimise-memory-undo.sh`

日常习惯：
- `about:unloads`：手动卸载最占内存的标签页（标签还在，点开重新加载）
- 看完的视频页（B 站等）及时关
- 感觉卡时重启 Firefox：恢复的标签页只有点开才加载，内存一下降很多

## 常用查看命令

```bash
free -h                                          # 内存和交换总览（看 available 列）
grep -i zswap /proc/meminfo                      # Zswapped 是压缩前大小，Zswap 是压缩后占的内存
cat /sys/module/zswap/parameters/compressor      # 当前压缩算法
tuned-adm active                                 # 当前电源模式
cat /proc/pressure/memory                        # 内存压力（avg10 持续大于 10 说明经常卡在等内存）

# 按程序汇总占用的内存（RSS）
ps -eo rss,comm --sort=-rss | awk 'NR>1 {a[$2]+=$1} END {for (k in a) printf "%6.0f MB  %s\n", a[k]/1024, k}' | sort -rn | head
```

程序名里的 `Isolated Web Co` 是 Firefox 的网页进程；`claude` 和版本号样子的进程是 Claude Code。
