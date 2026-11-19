# 官方发行版 Windows PDB 与 Visual Studio 调试

本文说明如何使用 [GitHub Releases](https://github.com/obsproject/obs-studio/releases) 上公开的 **OBS-Studio-*-Windows-x64-PDBs.zip**，对本机 **33.0.1 x64** 官方二进制做源码级调试，并与工作区内 `obs-studio-33.0.1/` 源码对齐。

## 一、结论速览

| 项目 | 说明 |
| --- | --- |
| 是否有公开 PDB | **有**。正式版 / 预发布版 Release 资产中均附带 `*-Windows-x64-PDBs.zip`（另有 ARM64）。 |
| 推荐版本 | **33.0.1 x64**（与工作区源码 tag 一致）。 |
| PDB 下载 | [OBS-Studio-33.0.1-Windows-x64-PDBs.zip](https://github.com/obsproject/obs-studio/releases/download/33.0.1/OBS-Studio-33.0.1-Windows-x64-PDBs.zip) |
| 便携二进制 | [OBS-Studio-33.0.1-Windows-x64.zip](https://github.com/obsproject/obs-studio/releases/download/33.0.1/OBS-Studio-33.0.1-Windows-x64.zip) |
| 官网安装包 | 一般不单独提供 PDB，请到 **GitHub Release Assets** 下载 PDB。 |

### 本工作区已准备好的运行目录

```
obs-runtime-33.0.1/
├── OBS-Studio-33.0.1-Windows-x64.zip          # 已下载（校验见下）
├── OBS-Studio-33.0.1-Windows-x64-PDBs.zip   # 已下载
├── install/                                   # 便携包 + PDB 合并解压（体积大，已 .gitignore）
├── verify-symbols.ps1                         # DbgHelp 符号加载自检
└── .gitignore
```

**SHA256（与 Release 页一致）：**

- `OBS-Studio-33.0.1-Windows-x64-PDBs.zip`: `f43a4360e894c952b97741d94dc3f1516a052ad7bf94ee2feaa5fd2a24bddc26`
- `OBS-Studio-33.0.1-Windows-x64.zip`: `0d9436451c2d772b33428e3fdae9776f071895c335de17283176306fb72651d3`

重新部署（解压合并）：

```powershell
$root = "E:\code\AI\Obs-Study\obs-runtime-33.0.1"
$install = Join-Path $root "install"
Expand-Archive (Join-Path $root "OBS-Studio-33.0.1-Windows-x64.zip") -DestinationPath $install -Force
Expand-Archive (Join-Path $root "OBS-Studio-33.0.1-Windows-x64-PDBs.zip") -DestinationPath $install -Force
.\verify-symbols.ps1
```

## 二、PDB 范围与调试预期

官方 Windows Release CI 会对多数插件 PDB 做 **strip**（见源码内 `.github/actions/windows-signing/config_x64.toml`），**不 strip** 的典型包括：

- `obs64.pdb`（主程序）
- `obs.pdb`（libobs）
- `obs-frontend-api.pdb`

因此：

- **主程序 + libobs**：断点、调用栈、源码单步 **通常可用**（Release 优化下体验略逊于本地 Debug 自编译）。
- **大量 obs-plugins DLL**：符号可能不完整，不宜指望每个插件都能逐行调试。

若需全量符号，请本地 `cmake --preset windows-x64` 自编译 Debug / RelWithDebInfo。

## 三、Visual Studio 配置

### 1. 打开源码

1. 启动 **VS 2022 或 VS 2026**，**文件 → 打开 → 文件夹**，选择 `obs-studio-33.0.1/`（含 `CMakeLists.txt`）。
2. 首次在本机执行安装脚本（脚本会按当前克隆路径改写模板中的工作区根，并写入 **`obs-studio-33.0.1/.vs/launch.vs.json`**）：

   ```powershell
   # VS 2026 或工具栏未出现启动项时，推荐模板：
   .\obs-runtime-33.0.1\setup-vs-debug.ps1 -Template launch.vs2026.json

   # 沿用旧版 launch.vs.json 模板：
   .\obs-runtime-33.0.1\setup-vs-debug.ps1
   ```

   **不要使用 `launch.json`**：那是 **VS Code / Cursor** 的配置名。Visual Studio「打开文件夹」只识别 **`launch.vs.json`**（位于代码根目录或 **`.vs/`** 下）。

3. 安装后的启动配置包含：
   - 启动项：`OBS 33.0.1 官方二进制 (GitHub PDB)`
   - 可执行文件：`obs-runtime-33.0.1/install/bin/64bit/obs64.exe`
   - `_NT_SYMBOL_PATH` 已指向 `obs-runtime-33.0.1/install`

### 2. 符号路径（若手动配置）

**工具 → 选项 → 调试 → 符号**，添加缓存目录并加入符号文件位置：

```
E:\code\AI\Obs-Study\obs-runtime-33.0.1\install
```

或设置用户/系统环境变量：

```
_NT_SYMBOL_PATH=SRV*https://msdl.microsoft.com/download/symbols;E:\code\AI\Obs-Study\obs-runtime-33.0.1\install
```

### 3. 确认符号已加载

1. **调试 → 窗口 → 模块**，启动或附加到 `obs64.exe`。
2. 查看 `obs64.exe`、`obs.dll` 的「符号状态」应为 **已加载符号**。
3. 或在本机运行：`obs-runtime-33.0.1\verify-symbols.ps1`（`SymType=SymPdb` 表示 DbgHelp 已解析 PDB）。

### 4. 源码路径

PDB 内记录的路径来自 GitHub Actions 构建机（常为 `D:\a\obs-studio\obs-studio\...` 一类）。首次断点停住时若提示找不到源文件：

- 在对话框中 **浏览** 到工作区 `obs-studio-33.0.1\` 下对应文件；
- VS 会记住映射，后续同前缀路径会自动解析。

### 5. 建议试调断点

| 位置 | 文件 | 说明 |
| --- | --- | --- |
| 进程入口 | `frontend/obs-main.cpp` → `main` | 启动路径 |
| libobs 初始化 | `libobs/obs.c` / `obs-app` 相关 | 核心初始化 |

使用 `launch.vs.json` **F5** 启动，或在 OBS 已运行时 **调试 → 附加到进程 → obs64.exe**。

### 6. Visual Studio 2026 与迁移

| 现象 | 处理 |
| --- | --- |
| 拷贝模板后改名为 `launch.json` | 改回安装为 `.vs/launch.vs.json` |
| 从 VS 2022 迁移后无启动项 / 调试适配器异常 | 关闭 VS，删除 `obs-studio-33.0.1/.vs` 后重新运行 `setup-vs-debug.ps1` |
| 工具栏未见启动项 | **解决方案资源管理器 → 显示所有文件**，确认 `.vs/launch.vs.json` 存在；启动项下拉选 **「OBS 33.0.1 官方二进制 (GitHub PDB)」** |

VS 2026 与 VS 2022 共用同一 **`launch.vs.json`** schema（`version: 0.2.1`），无 `launch.vs2026.json` 官方文件名。仓库中的 [launch.vs2026.json](../obs-runtime-33.0.1/launch.vs2026.json) 仅为经整理的模板，须由脚本或手动复制为 `.vs/launch.vs.json` 后才会被 IDE 加载。

命令行替代：

```powershell
& "D:\soft\vs2022\ide\Common7\IDE\devenv.com" /debugexe "E:\code\AI\Obs-Study\obs-runtime-33.0.1\install\bin\64bit\obs64.exe"
```

（请将 `devenv.com` 路径改为你本机 VS 安装路径。）

## 四、官方 CI 如何发布 PDB

标签 push 后 [`.github/workflows/push.yaml`](../obs-studio-33.0.1/.github/workflows/push.yaml) 将 CI 产物重命名为 `OBS-Studio-{version}-Windows-x64-PDBs.zip` 并上传到 GitHub Release。命名规则在 [`.github/actions/windows-signing/config_x64.toml`](../obs-studio-33.0.1/.github/actions/windows-signing/config_x64.toml) 的 `[package.zip] pdb_name` 中定义。

## 五、与本仓库其它文档的关系

| 文档 | 关系 |
| --- | --- |
| [README.md](../README.md) | 33.0.1 源码下载与构建索引 |
| [01-架构设计.md](./01-架构设计.md) | 理解断点所在模块与子系统 |
| [03-软件时序图.md](./03-软件时序图.md) | 对照启动 / 推流时序设断点 |