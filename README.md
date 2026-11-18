# OBS Studio 33.0.1 源码分析

> 本工作区包含 OBS Studio 官方源码副本（`obs-studio-33.0.1/`）与一套中文源码分析文档（架构设计、模块划分、时序图、类图、动态数据流可视化）。分析文档位于工作区根目录，不存放在源码路径内。

## 源码下载信息

| 项目 | 内容 |
| --- | --- |
| 项目名称 | OBS Studio |
| 版本 | 33.0.1 |
| 官方仓库 | <https://github.com/obsproject/obs-studio> |
| **本源码下载地址** | <https://github.com/obsproject/obs-studio/archive/refs/tags/33.0.1.zip> |
| 许可证 | GPL-2.0-or-later（见 [COPYING](obs-studio-33.0.1/COPYING)） |
| 官方文档 | <https://obsproject.com/docs>（源码内 Sphinx 文档位于 [docs/sphinx/](obs-studio-33.0.1/docs/sphinx/)） |

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

> 动态可视化页面（含流动动画的数据流图）由分析工具生成，入口见
> [docs-analysis/05-动态数据流可视化.md](docs-analysis/05-动态数据流可视化.md)。

## 快速构建（参考官方 CI）

```powershell
# Windows（需先安装 Qt6、FFmpeg 预编译依赖，详见官方 Wiki）
cmake --preset windows-x64
cmake --build --preset windows-x64
```

官方构建指南：<https://github.com/obsproject/obs-studio/wiki/Install-Instructions>

## 说明

- 工作区根目录的 `README.md` 与 `docs-analysis/` 为本地新增的中文分析材料，非官方源码内容；源码目录 `obs-studio-33.0.1/` 仅保留官方源码；
- 官方原始说明见 [README.rst](obs-studio-33.0.1/README.rst)。