# OBS 33.0.1 x64 官方运行包 + PDB（本地调试用）

Git 仅跟踪脚本与说明；`*.zip` 与 `install/` 见 [.gitignore](./.gitignore)。

| 文件 | 说明 |
| --- | --- |
| `OBS-Studio-33.0.1-Windows-x64.zip` | 官方便携二进制 |
| `OBS-Studio-33.0.1-Windows-x64-PDBs.zip` | 官方 PDB 包 |
| `install/` | 解压合并后的可运行目录（`bin/64bit/obs64.exe` + 50 个 `.pdb`） |
| `launch.vs.json` | VS 启动配置模板（入库副本） |
| `setup-vs-debug.ps1` | 安装 `launch.vs.json` 到 `obs-studio-33.0.1/.vs/` |
| `verify-symbols.ps1` | DbgHelp 校验 `obs64.exe` / `obs.dll` 的 `SymPdb` |

完整 VS 步骤见 [docs-analysis/06-官方PDB与VS调试.md](../docs-analysis/06-官方PDB与VS调试.md)。