# OBS Studio 33.0.1 源码分析

> 本工作区包含 OBS Studio 官方源码副本（`obs-studio-33.0.1/`）与一套中文源码分析文档（架构设计、模块划分、时序图、类图、动态数据流可视化）。分析文档位于工作区根目录，不存放在源码路径内。

## 源码下载信息

| 项目 | 内容 |
| --- | --- |
| 项目名称 | OBS Studio |
| 版本 | 33.0.1 |
| 官方仓库 | <https://github.com/obsproject/obs-studio> |
| **本源码下载地址** | <https://github.com/obsproject/obs-studio/archive/refs/tags/33.0.1.zip> |
| **编译用完整源码（推荐）** | `git clone --recursive` + `git checkout 33.0.1`（zip 归档**不含** git 子模块，见 [07-Windows编译指南.md](docs-analysis/07-Windows编译指南.md)） |
| 许可证 | GPL-2.0-or-later（见 [COPYING](obs-studio-33.0.1/COPYING)） |
| 官方文档 | <https://obsproject.com/docs>（源码内 Sphinx 文档位于 [docs/sphinx/](obs-studio-33.0.1/docs/sphinx/)） |

## 官方发行版下载（Windows x64 · 33.0.1）

GitHub [Releases](https://github.com/obsproject/obs-studio/releases) / [33.0.1 发行页](https://github.com/obsproject/obs-studio/releases/tag/33.0.1) 提供与 tag 对齐的 Windows 二进制及**公开 PDB**。官网安装包一般不附带 PDB，调试符号请在 GitHub Release Assets 下载。

| 资产 | 用途 | 下载地址 |
| --- | --- | --- |
| Release 列表 | 查看各版本及 PDB 附件 | <https://github.com/obsproject/obs-studio/releases> |
| Sources.tar.gz | Release 同源代码包（校验用） | <https://github.com/obsproject/obs-studio/releases/download/33.0.1/OBS-Studio-33.0.1-Sources.tar.gz> |
| **Windows-x64.zip** | 官方便携二进制（推荐调试） | <https://github.com/obsproject/obs-studio/releases/download/33.0.1/OBS-Studio-33.0.1-Windows-x64.zip> |
| **Windows-x64-PDBs.zip** | 公开 Windows 调试符号（PDB） | <https://github.com/obsproject/obs-studio/releases/download/33.0.1/OBS-Studio-33.0.1-Windows-x64-PDBs.zip> |
| Windows-x64-Installer.exe | 安装版（与官网一致，可选） | <https://github.com/obsproject/obs-studio/releases/download/33.0.1/OBS-Studio-33.0.1-Windows-x64-Installer.exe> |

**SHA256（与 Release 页 Checksums 一致）：**

- `OBS-Studio-33.0.1-Windows-x64-PDBs.zip`：`f43a4360e894c952b97741d94dc3f1516a052ad7bf94ee2feaa5fd2a24bddc26`
- `OBS-Studio-33.0.1-Windows-x64.zip`：`0d9436451c2d772b33428e3fdae9776f071895c335de17283176306fb72651d3`

本工作区本地运行目录：[obs-runtime-33.0.1/](obs-runtime-33.0.1/)（脚本与说明见 [obs-runtime-33.0.1/README.md](obs-runtime-33.0.1/README.md)；`install/` 与 `*.zip` 已 gitignore，需自行下载或解压）。

## OBS Studio 简介

OBS Studio 是一款免费开源的**视频直播推流与屏幕录制**软件，支持 Windows / macOS / Linux。
其核心能力包括：

- 多来源实时采集：显示器 / 游戏 / 窗口捕获、摄像头、麦克风、桌面音频、媒体文件、浏览器页面等；
- 场景化合成：场景（Scene）+ 源（Source）+ 滤镜（Filter）+ 转场（Transition）的层级化视频合成；
- 实时编码输出：x264 / NVENC / QSV / VideoToolbox / AV1 等编码器，RTMP / SRT / RIST / WHIP 推流与本地录制；
- 高度可扩展：基于 C 语言插件框架（libobs），四类插件对象（Source / Output / Encoder / Service）均可动态加载。

## 源码目录结构（obs-studio-33.0.1/）

```text
obs-studio-33.0.1/
├── libobs/            # 核心库：管线调度、音视频子系统、插件框架、图形抽象层
│   ├── graphics/      #   图形子系统抽象（effect/texture/shader 等）
│   ├── media-io/      #   音视频 IO 线程与缓冲（video-io / audio-io / 重采样）
│   ├── callback/      #   信号(signal)与过程(proc)回调机制
│   └── util/          #   基础设施（内存/线程/配置/日志/序列化等）
├── libobs-d3d11/      # 图形后端：Direct3D 11（Windows）
├── libobs-opengl/     # 图形后端：OpenGL（Windows/Linux）
├── libobs-metal/      # 图形后端：Metal（macOS，Swift 实现）
├── libobs-winrt/      # Windows WinRT 捕获支持（WGC 窗口/显示器捕获）
├── frontend/          # Qt 前端 UI（OBSApp / OBSBasic / 对话框 / 设置 / 插件管理器）
├── plugins/           # 40+ 官方插件（采集/编码/输出/滤镜/转场/服务）
├── shared/            # 前后端共享代码（属性视图、QT 包装、媒体播放等）
├── deps/              # 第三方依赖（子模块：libff、curl、jansson 等）
├── cmake/             # CMake 构建脚本（平台/查找器/打包）
├── docs/sphinx/       # 官方英文设计文档（backend-design / frontends / graphics 等）
├── test/              # 单元测试
└── build-aux/         # 格式化与 CI 辅助脚本
```

## 源码分析文档索引（中文）

所有分析文档位于 [docs-analysis/](docs-analysis/) 目录：

| 文档 | 内容 |
| --- | --- |
| [01-架构设计.md](docs-analysis/01-架构设计.md) | 分层架构、三大线程模型、插件对象模型、图形抽象、引用计数与信号机制 |
| [02-模块划分.md](docs-analysis/02-模块划分.md) | 各目录/模块职责、依赖关系、插件清单与关键文件导读 |
| [03-软件时序图.md](docs-analysis/03-软件时序图.md) | 启动初始化、开始推流、视频帧管线、音频混音、停止与关闭等 Mermaid 时序图 |
| [04-类图设计.md](docs-analysis/04-类图设计.md) | libobs 核心对象结构体"类图"、插件接口（info 结构）、场景树、前端 Qt 类关系 |
| [05-动态数据流可视化.md](docs-analysis/05-动态数据流可视化.md) | 运行时数据流动态图（HTML）的说明与入口 |
| [06-官方PDB与VS调试.md](docs-analysis/06-官方PDB与VS调试.md) | GitHub 发行版 PDB 下载、本机部署与 Visual Studio 调试步骤 |
| [07-Windows编译指南.md](docs-analysis/07-Windows编译指南.md) | Windows 上按版本编译 OBS：依赖来源、CMake Preset、验收与排错 |

> 动态可视化页面（含流动动画的数据流图）由分析工具生成，入口见
> [docs-analysis/05-动态数据流可视化.md](docs-analysis/05-动态数据流可视化.md)。

## 官方二进制 + PDB 调试（Visual Studio）

在**不本地编译**的情况下，用发行版 `obs64.exe` + GitHub PDB 对照本仓库 `obs-studio-33.0.1/` 源码调试。

1. **下载**：`Windows-x64.zip` 与 `Windows-x64-PDBs.zip`（见上表），或复用 [obs-runtime-33.0.1/](obs-runtime-33.0.1/) 中已下载的 zip。
2. **部署**：将两份 zip 解压到同一根目录（本仓库默认 `obs-runtime-33.0.1/install/`），使 `bin/64bit/obs64.pdb` 与 `obs64.exe`、`obs.pdb` 与 `obs.dll` 位于同一目录。
3. **打开工程**：VS 2022 / VS 2026 → **文件 → 打开 → 文件夹** → `obs-studio-33.0.1/`（含 `CMakeLists.txt`）。
4. **启动配置**：运行 `obs-runtime-33.0.1/setup-vs-debug.ps1`，将 **`type: "default"`** 的 [launch.vs.json](obs-runtime-33.0.1/launch.vs.json) 安装到 `obs-studio-33.0.1/.vs/launch.vs.json`（勿用 `cppdbg` / `launch.json`）。修改模板后须重装并**重启 VS**。详见 [06-官方PDB与VS调试.md](docs-analysis/06-官方PDB与VS调试.md) 排错小节。
5. **启动调试**：工具栏启动项选 **「OBS 33.0.1 官方二进制 (GitHub PDB)」**，按 F5。
6. **符号路径**（若未走 launch 配置）：**工具 → 选项 → 调试 → 符号**，添加 `obs-runtime-33.0.1/install`；或环境变量 `_NT_SYMBOL_PATH=SRV*https://msdl.microsoft.com/download/symbols;<工作区>/obs-runtime-33.0.1/install`。
7. **验证**：**调试 → 窗口 → 模块** 中 `obs64.exe`、`obs.dll` 应为「已加载符号」；或运行 `obs-runtime-33.0.1/verify-symbols.ps1`（`SymType=SymPdb` 表示 PDB 可用）。
8. **断点**：建议在 `frontend/obs-main.cpp` 的 `main` 设断点做首次命中；若提示源路径为 CI 路径（如 `D:\a\obs-studio\...`），浏览映射到本仓库 `obs-studio-33.0.1/` 对应文件。
9. **预期**：主程序与 libobs 符号较完整；多数插件 PDB 在官方 CI 中会被 strip，不宜指望所有 DLL 都能逐行单步。需全量符号时可本地 `cmake --preset windows-x64` 自编译 Debug。

解压合并示例（路径请按本机工作区根目录调整）：

```powershell
$root = "E:\code\AI\Obs-Study\obs-runtime-33.0.1"
$install = Join-Path $root "install"
Expand-Archive (Join-Path $root "OBS-Studio-33.0.1-Windows-x64.zip") -DestinationPath $install -Force
Expand-Archive (Join-Path $root "OBS-Studio-33.0.1-Windows-x64-PDBs.zip") -DestinationPath $install -Force
& (Join-Path $root "verify-symbols.ps1")
```

源码路径映射、符号范围与 CI 发布说明见 [06-官方PDB与VS调试.md](docs-analysis/06-官方PDB与VS调试.md)。

## Windows 从源码构建（摘要 · 33.0.1）

**可以直接用 CMake Preset 构建**；Qt6 / FFmpeg 等大依赖不必手找源码 — Configure 时按 [`CMakePresets.json`](obs-studio-33.0.1/CMakePresets.json) 自动下载 **obs-deps**、**Qt6**、**CEF** 到 `obs-studio-33.0.1/.deps/`。

1. **源码**：`git clone --recursive` 并 `git checkout 33.0.1`（本仓库 zip 副本缺子模块，不能直接完整编译）。
2. **工具**：CMake ≥ 3.28；Visual Studio 与 preset 一致（33.0.1 为 **Visual Studio 18 2026**，见 07 文档）。
3. **配置与编译**（VS 2026，一键脚本）：

```powershell
# 仓库根目录
.\scripts\build-obs-windows-RelWithDebInfo.ps1   # 日常 / 接近官方
.\scripts\build-obs-windows-Debug.ps1            # 深度调试
```

手工等价命令与参数说明：[scripts/README.md](scripts/README.md)、[07-Windows编译指南.md](docs-analysis/07-Windows编译指南.md)。

4. **成功标志**：Configure 日志中 obs-deps / Qt6 等为 `done`；生成 `obs64.exe`（常在 `build_x64/rundir`）。
5. **细节与排错**（依赖三层、手动 `CMAKE_PREFIX_PATH`、与发行版 PDB 对比）：[07-Windows编译指南.md](docs-analysis/07-Windows编译指南.md)。

仅安装官方已编译包（非从源码构建）：<https://github.com/obsproject/obs-studio/wiki/Install-Instructions>

## 说明

- 工作区根目录的 `README.md` 与 `docs-analysis/` 为本地新增的中文分析材料，非官方源码内容；源码目录 `obs-studio-33.0.1/` 仅保留官方源码；
- 根目录 README 汇总 **发行版下载**、**PDB 调试** 与 **Windows 编译摘要**；详解见 [06-官方PDB与VS调试.md](docs-analysis/06-官方PDB与VS调试.md)、[07-Windows编译指南.md](docs-analysis/07-Windows编译指南.md)；
- 官方原始说明见 [README.rst](obs-studio-33.0.1/README.rst)。