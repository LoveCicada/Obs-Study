# Obs-Study 构建脚本

面向本仓库 **OBS Studio 33.0.1**、**Windows x64**、官方 CMake preset **`windows-x64`**（生成器 **Visual Studio 18 2026**）。

| 脚本 | 配置 | 说明 |
| --- | --- | --- |
| [`build-obs-windows-RelWithDebInfo.ps1`](build-obs-windows-RelWithDebInfo.ps1) | RelWithDebInfo | 接近官方 CI 默认，带调试符号 |
| [`build-obs-windows-Debug.ps1`](build-obs-windows-Debug.ps1) | Debug | 完整符号，便于断点单步 |

在仓库根目录执行：

```powershell
.\scripts\build-obs-windows-RelWithDebInfo.ps1
.\scripts\build-obs-windows-Debug.ps1
```

常用参数（传给 common）：

```powershell
.\scripts\build-obs-windows-Debug.ps1 -Reconfigure
.\scripts\build-obs-windows-RelWithDebInfo.ps1 -SkipConfigure
```

前置条件见 [docs-analysis/07-Windows编译指南.md](../docs-analysis/07-Windows编译指南.md)（CMake 3.28+、VS 2026、git 子模块齐全）。