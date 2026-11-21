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

1. 启动 **VS 2022**（或更新版本），**文件 → 打开 → 文件夹**，选择 `obs-studio-33.0.1/`（含 `CMakeLists.txt`）。
2. 首次在本机执行安装脚本（将 [launch.vs.json](../obs-runtime-33.0.1/launch.vs.json) 写入 **`obs-studio-33.0.1/.vs/launch.vs.json`**，并替换其中的 `__REPO_ROOT__`）：

   ```powershell
   .\obs-runtime-33.0.1\setup-vs-debug.ps1
   ```

   - Visual Studio 只识别 **`launch.vs.json`**（位于所打开文件夹根目录或 **`.vs/`** 下），**不要**使用 `launch.json`（那是 VS Code / Cursor 的文件名）。
   - 本模板对官方二进制使用 **`"type": "default"`**，`project` 指向相对路径 `../obs-runtime-33.0.1/install/bin/64bit/obs64.exe`（见 [微软说明](https://learn.microsoft.com/en-us/visualstudio/ide/customize-build-and-debug-tasks-in-visual-studio?view=vs-2022)）。
   - 修改模板或克隆到新路径后，**务必重跑** `setup-vs-debug.ps1`，并**完全重启 VS**。

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

### 6. 启动项不显示（排错）

| 现象 | 原因与处理 |
| --- | --- |
| 工具栏为 **「选择启动项…」**，配置显示 **「无配置」** | 多为 `launch.vs.json` 使用了 **`type: "cppdbg"`**（仅适用于远程/WSL，见 [CMake 调试文档](https://learn.microsoft.com/en-us/cpp/build/configure-cmake-debugging-sessions?view=msvc-170)）。本地 Windows 官方便携 exe 应使用 **`type: "default"`**，且 `project` 为 **exe 相对路径**，不要用 `CMakeLists.txt` + `program`。重跑 `setup-vs-debug.ps1` 后重启 VS。 |
| 修改了 `obs-runtime/launch.vs.json` 但未安装到 `.vs/` | 仅编辑仓库模板不会生效；须运行 `setup-vs-debug.ps1`。 |
| CMake 未 Configure | 调试官方 exe **不必**成功 Configure；「无配置」可忽略。若要 F5 自编译 `obs-studio`，再选 `windows-x64` Preset 并生成。 |
| 仍无下拉项 | **调试 → 调试和启动设置** 打开 `launch.vs.json` 保存一次；或关闭 VS 删除 `obs-studio-33.0.1/.vs` 后重装配置。 |
| `../obs-runtime/...` 仍无法启动 | 少数环境下 VS 不解析文件夹外 exe；改用 **调试 → 其他调试目标 → 调试已启动的 executable**，手动选 `install/bin/64bit/obs64.exe`（工作目录设为同目录）。 |

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
| [07-Windows编译指南.md](./07-Windows编译指南.md) | **本地自编译** `obs64.exe`：全模块符号优于官方 Release PDB，适合改代码后调试 |
| [01-架构设计.md](./01-架构设计.md) | 理解断点所在模块与子系统 |
| [03-软件时序图.md](./03-软件时序图.md) | 对照启动 / 推流时序设断点 |

**自编译 vs 官方 PDB**：发行版 + GitHub PDB 适合快速对照 **33.0.1 tag** 源码读逻辑；若需插件级单步或改代码验证，请按 [07-Windows编译指南.md](./07-Windows编译指南.md) 在 Windows 上 `cmake --preset windows-x64` 自编译。