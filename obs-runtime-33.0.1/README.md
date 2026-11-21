# OBS 33.0.1 x64 官方运行包 + PDB（本地调试用）

Git 仅跟踪脚本与说明；`*.zip` 与 `install/` 见 [.gitignore](./.gitignore)。

| 文件 | 说明 |
| --- | --- |
| `OBS-Studio-33.0.1-Windows-x64.zip` | 官方便携二进制 |
| `OBS-Studio-33.0.1-Windows-x64-PDBs.zip` | 官方 PDB 包 |
| `install/` | 解压合并后的可运行目录（`bin/64bit/obs64.exe` + 50 个 `.pdb`） |
| `launch.vs.json` | VS **打开文件夹**调试模板（`type: default`，`__REPO_ROOT__` 占位符） |
| `setup-vs-debug.ps1` | 安装为 `obs-studio-33.0.1/.vs/launch.vs.json` 并展开仓库根路径 |
| `verify-symbols.ps1` | DbgHelp 校验 `obs64.exe` / `obs.dll` 的 `SymPdb` |

安装启动项后请在 VS 工具栏选择 **「OBS 33.0.1 官方二进制 (GitHub PDB)」**。若仍为「选择启动项…」，见 [06-官方PDB与VS调试.md](../docs-analysis/06-官方PDB与VS调试.md) 第六节。

完整 VS 步骤见 [docs-analysis/06-官方PDB与VS调试.md](../docs-analysis/06-官方PDB与VS调试.md)。