# ZL-Z2-WIN10系统安装记录

## 准备

### 基本环境

* 笔记本: 机械革命 Z2 商务版
* 辅助安装环境: Arch Linux, qemu, libvirt, virt-manager，samba 共享
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

### 备份系统

执行`virsh define /data/shared/ZLZD-mini.xml`恢复光驱和网卡。

virt-manager 中重新放入 Windows 安装光盘，从光盘启动开机。

在 PE 系统中输入以下命令备份：
```
wpeutil InitializeNetwork
net use V: \\ZL-Z2-HOST\data

diskpart

dism /Capture-Image /ImageFile:V:\shared\Win10-01-OSInstalled-ESP.wim /CaptureDir:P:\ /Name:Win10OS-ESP /Compress:max /CheckIntegrity /Verify /EA
dism /Capture-Image /ImageFile:V:\shared\Win10-01-OSInstalled-WinRE.wim /CaptureDir:R:\ /Name:Win10OS-WinRE /Compress:max /CheckIntegrity /Verify /EA
dism /Capture-Image /ImageFile:V:\shared\Win10-01-OSInstalled.wim /CaptureDir:C:\ /Name:Win10OS /Compress:max /CheckIntegrity /Verify /EA
```

下一步仍然需要 PE 环境，所以不要关机。

改进思路：

1. 在设置用户名等之前备份（但注意此时 WinRE 分区可能还没有内容）
1. 备份前将此安装记录放在桌面

## 第一轮系统设置

### 安装 Windows 应用商店 APP

准备好从 Windows 10 1809 安装光盘镜像提取的 Windows Store 文件：[winstore_84ac403f.wim](winstore_84ac403f.wim)。

在 PE 系统中用这个命令导入 C 盘：`dism /Apply-Image /ImageFile:V:\shared\winstore_84ac403f.wim /ApplyDir:C:\ /Index:1 /CheckIntegrity /Verify /EA`。

将下一步需要的命令复制到 D 盘。
然后关机，删除光驱设备（保留网卡设备），从硬盘启动。

进入桌面后，以管理员身份打开 PowerShell，执行以下命令：
```
Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.VCLibs.140.00_14.0.25426.0_x64__8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode
Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.VCLibs.140.00_14.0.25426.0_x86__8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode

Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.NET.Native.Runtime.1.6_1.6.24903.0_x64__8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode
Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.NET.Native.Runtime.1.6_1.6.24903.0_x86__8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode
Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.NET.Native.Runtime.1.7_1.7.25531.0_x64__8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode
Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.NET.Native.Runtime.1.7_1.7.25531.0_x86__8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode

Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.NET.Native.Framework.1.6_1.6.24903.0_x64__8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode
Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.NET.Native.Framework.1.6_1.6.24903.0_x86__8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode
Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.NET.Native.Framework.1.7_1.7.25531.0_x64__8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode
Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.NET.Native.Framework.1.7_1.7.25531.0_x86__8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode

Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.Advertising.Xaml_10.1804.2.0_x64__8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode
Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.Advertising.Xaml_10.1804.2.0_x86__8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode

Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.WindowsStore_11805.1001.49.0_x64__8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode
Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.WindowsStore_11805.1001.49.0_neutral_split.language-zh-hans_8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode
Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.WindowsStore_11805.1001.49.0_neutral_split.scale-100_8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode
Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.WindowsStore_11805.1001.49.0_neutral_split.scale-125_8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode
#Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.WindowsStore_11805.1001.4913.0_neutral_~_8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode

Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.StorePurchaseApp_11805.1001.8.0_x64__8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode
Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.StorePurchaseApp_11805.1001.8.0_neutral_split.language-zh-hans_8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode
Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.StorePurchaseApp_11805.1001.8.0_neutral_split.scale-100_8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode
#Add-AppXPackage -Register 'C:\Program Files\WindowsApps\Microsoft.StorePurchaseApp_11805.1001.813.0_neutral_~_8wekyb3d8bbwe\AppXManifest.xml' -DisableDevelopmentMode

```

然后在开始菜单中打开 Microsoft Store，让它升级自己。

### 其他设置

更改硬件时钟为 UTC：
打开注册表编辑器，找到`HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\TimeZoneInformation`，新建 DWORD 项，名字为`RealTimeIsUniversal`，值为1。

在 Windows 设置中更改计算机名为`ZL-Z2-WIN10`。

重启检查是否生效。

### 语言包

在 Windows 设置中添加英语语言包。

安装中文和英语的“本地体验包”。

### 更新系统

在 Windows 设置中更新系统。反复检查到没有更新为止。

### 磁盘清理

重启，清理磁盘。
然后`shutdown /s /t 0`关机。

### 备份

`virsh define`命令加载`ZLZD-mini.xml`虚拟机配置文件。
启动进入 PE 系统。
将此文件放在桌面。
然后按前面的方法备份系统，备份命令为：
```
dism /Capture-Image /ImageFile:V:\shared\Win10-02-Settings1.wim /CaptureDir:C:\ /Name:Win10S1 /Compress:max /CheckIntegrity /Verify /EA
```

## 驱动程序及第二轮系统设置

### 杂项

文件资源管理器工具栏展开

### 开始菜单磁贴

### Z2 驱动

* IntelChipset-HM370-intel.com-10.1.18-201911.zip
* IntelGraphics-8750H-intel.com-26.20.100.7755-202001.zip
* NvidiaVideo-1050Mobile-nvidia.com-442.19-202001-notebook-win10-64bit-international-dch-whql.exe
* IntelWiFi-AC9462-intel.com-21.60.2.1-201912-Win10x64.exe
* RealtekGbE-8168-realtek.com-10.038.1118.2019-201911-Install_Win10_10038_12202019.zip
* IntelBT-AC9462-intel.com-21.60.0.4-201912-Win10x64.zip
* RealtekAudio-UAD-Mechrevo-6.0.1.8428-201804.zip
* RealtekAudio-CreativeAudioEffectsComponent-MicrosoftCatalog-2.0.0.33-201902-01c279d6-63f6-456d-ae97-58eb8aad8571_735dbb94048705b3bf418d6c4c2bc00e8cc1a8aa.cab
* RealtekAudio-SoundBlasterConnect-MicrosoftCatalog-2.2.7.0-201902-24af12bc-5337-4c9d-ba6e-ed58b44d1d98_2893ee4790bb16f40c631855d5756cac7abcb018.cab
* IntelSerialIO-NUC8-intel.com-30.100.1915.1-201904.zip
* RealtekCardReader-0BDA0129-MicrosoftCatalog-10.0.18362.31255-201912-9f6111f9-3297-47a8-8ca3-5dc42897bad6_33bc07eb8e141f73627a0acb2ded5f50e7775024.cab
* IntelMEI-MEI-MicrosoftCatalog-1815.12.0.2021-201804-451de8b6-0274-4e77-becb-717c42774929_b0558e18ccc5bbea3a662a745d753ae7be049c80.cab
* ControlCenter

### QEMU 驱动

#### 驱动准备

#### 驱动安装

## 应用软件
