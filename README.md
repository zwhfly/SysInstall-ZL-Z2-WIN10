# ZL-Z2-WIN10系统安装记录

## 准备

### 基本环境

* 笔记本: 机械革命 Z2 商务版
* 辅助安装环境: Arch Linux, qemu, libvirt, virt-manager
* SSD: BC501 NVMe SK hynix 256GB

### 清空硬盘

```
blkdiscard /dev/nvme1n1
nvme id-ctrl -H /dev/nvme1
nvme format /dev/nvme1 --ses=1 -n 1
poweroff # then power on
blkdiscard /dev/nvme1n1
```

### 硬盘分区

写入分区表：`dd if=/data/Z2SK250.WIN10.sectors of=/dev/nvme1n1 bs=512`（[Z2SK250.WIN10.sectors](Z2SK250.WIN10.sectors)）。

在分区管理器中创建然后删除一个分区，来修复[第二GPT](https://zh.wikipedia.org/wiki/GUID%E7%A3%81%E7%A2%9F%E5%88%86%E5%89%B2%E8%A1%A8)。

分区情况：
```
[root@ZL-Z2-HOST zl]# fdisk -o Device,Start,End,Sectors,Size,Type,Type-UUID,Attrs,Name,UUID -l /dev/nvme1n1
Disk /dev/nvme1n1：238.49 GiB，256060514304 字节，500118192 个扇区
磁盘型号：BC501 NVMe SK hynix 256GB               
单元：扇区 / 1 * 512 = 512 字节
扇区大小(逻辑/物理)：512 字节 / 512 字节
I/O 大小(最小/最佳)：512 字节 / 512 字节
磁盘标签类型：gpt
磁盘标识符：52AE126A-7977-2D4D-AADE-50CFB208E72F

设备                起点      末尾      扇区   大小 类型               类型-UUID                            属性                      名称                         UUID
/dev/nvme1n1p1      2048  10520575  10518528     5G EFI 系统           C12A7328-F81F-11D2-BA4B-00A0C93EC93B GUID:63                   EFI system partition         CB7F67C7-4BE8-49B7-A613-4141DEB837EA
/dev/nvme1n1p2  10522624  10784767    262144   128M Microsoft 保留     E3C9E316-0B5C-4DB8-817D-F92DF00215AE GUID:63                   Microsoft reserved partition 22B18734-3563-4753-A70D-417AAB5DDFD7
/dev/nvme1n1p3  10786816 346462207 335675392 160.1G Microsoft 基本数据 EBD0A0A2-B9E5-4433-87C0-68B6B72699C7                           Basic data partition         9694778E-9015-49BF-9296-F6BDC790D3FD
/dev/nvme1n1p4 346464256 348577791   2113536     1G Windows 恢复环境   DE94BBA4-06D1-4D40-A16A-BFD50179D6AC RequiredPartition GUID:63 Microsoft recovery partition D918F60E-1D6A-4B63-A2EF-CD8071CC6CDF
/dev/nvme1n1p5 348579840 499705855 151126016  72.1G Microsoft 基本数据 EBD0A0A2-B9E5-4433-87C0-68B6B72699C7                           Basic data partition         8B122E7F-E3D6-4F7F-BCA9-B7159FBB947B

```

### 虚拟机配置

* 安装初期采用最简配置：[ZLZD-mini.xml](ZLZD-mini.xml)
* 安装驱动前会切换到完整配置：[ZLZD.xml](ZLZD.xml)

```
virsh define /data/shared/ZLZD-mini.xml
```

## Windows 安装

### 用安装盘启动安装

准备安装光盘镜像文件：

|名称|cn_windows_10_enterprise_ltsc_2019_x64_dvd_9c09ff24.iso
|:--|:--
|大小|4478906368 字节 (4271 MiB)
|CRC32|0C3357E3
|SHA1|24B59706D5EDED392423936C82BA5A83596B50CC
|SHA256|AA4EA00581AA84999DBFE0627499B392E10C75912D6E2F1635EB7C4B9139FB5F

virt-manager中插入光盘镜像，设置引导选项为光盘引导，开机，期间注意按任意键从光盘启动。

进入 PE 系统后，用 diskpart 分配盘符，然后用资源管理器格式化。格式化信息：

|盘符|文件系统|标签
|:--|:--|:--
|P:|FAT32|ESP
|C:|NTFS|Win10
|R:|NTFS|WinRE
|D:|NTFS|Data

然后进入 Windows 安装程序正常安装。

### 重启后的安装操作

重启后不人工操作，会进入 OVMF 的 EFI Shell 环境。输入`reset -s`关机。

在 virt-manager 中移除光驱和网卡设备，检查引导选项为硬盘引导，开机。

按安装向导默认设置安装，除了以下设置：
* **用户名**：ZL
* **联网**：不联网
* **发送活动历史记录**：否
* **隐私设置**：仅开启“查找我的设备”和“位置”

进入桌面后，找到 cmd.exe，输入`shutdown /s /t 0`关机。

## 第一轮系统设置

## 驱动程序及第二轮系统设置

## 应用软件
