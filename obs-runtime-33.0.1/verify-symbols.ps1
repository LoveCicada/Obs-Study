# Validates official OBS 33.0.1 x64 PE <-> PDB layout and DbgHelp symbol resolution.
param(
    [string]$InstallRoot = (Join-Path $PSScriptRoot "install")
)

$ErrorActionPreference = "Stop"
$bin64 = Join-Path $InstallRoot "bin\64bit"

if (-not (Test-Path (Join-Path $bin64 "obs64.exe"))) {
    throw "obs64.exe not found under $bin64"
}

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class ObsSymbolCheck {
    const int MAX_PATH = 260;
    const int ERROR_SUCCESS = 0;

    [DllImport("dbghelp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern bool SymInitialize(IntPtr hProcess, string UserSearchPath, bool fInvadeProcess);

    [DllImport("dbghelp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern bool SymCleanup(IntPtr hProcess);

    [DllImport("dbghelp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern IntPtr SymLoadModuleEx(
        IntPtr hProcess, IntPtr hFile, string ModuleName, string ModuleBaseName,
        long BaseOfDll, int DllSize, IntPtr Data, int Flags);

    [DllImport("dbghelp.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern bool SymGetModuleInfo64(IntPtr hProcess, long qwAddr, ref IMAGEHLP_MODULE64 ModuleInfo);

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct IMAGEHLP_MODULE64 {
        public int SizeOfStruct;
        public long BaseOfImage;
        public int ImageSize;
        public int TimeDateStamp;
        public int CheckSum;
        public int NumSyms;
        public SYM_TYPE SymType;
        public int ModuleNameSize;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
        public string ModuleName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
        public string ImageName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
        public string LoadedImageName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
        public string LoadedPdbName;
    }

    public enum SYM_TYPE {
        SymNone = 0, SymCoff, SymCv, SymPdb, SymExport, SymDeferred, SymSym,
        SymDia, SymVirtual, NumSymTypes
    }

    public static string CheckModule(string searchPath, string modulePath) {
        var proc = System.Diagnostics.Process.GetCurrentProcess();
        if (!SymInitialize(proc.Handle, searchPath, false))
            throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error(), "SymInitialize failed");

        try {
            long baseAddr = 0x10000000;
            IntPtr baseMod = SymLoadModuleEx(proc.Handle, IntPtr.Zero, modulePath, null, baseAddr, 0, IntPtr.Zero, 0);
            if (baseMod == IntPtr.Zero)
                throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error(), "SymLoadModuleEx failed");

            var mi = new IMAGEHLP_MODULE64 { SizeOfStruct = Marshal.SizeOf(typeof(IMAGEHLP_MODULE64)) };
            if (!SymGetModuleInfo64(proc.Handle, baseAddr, ref mi))
                throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error(), "SymGetModuleInfo64 failed");

            return string.Format("SymType={0} Pdb={1}", mi.SymType, mi.LoadedPdbName ?? "(none)");
        } finally {
            SymCleanup(proc.Handle);
        }
    }
}
"@

$keys = @(
    @{ Name = "obs64.exe"; Path = Join-Path $bin64 "obs64.exe" },
    @{ Name = "obs.dll"; Path = Join-Path $bin64 "obs.dll" }
)

Write-Host "Install root: $InstallRoot"
Write-Host "Symbol search path (use in VS): $InstallRoot"
Write-Host ""

$missing = @()
foreach ($k in $keys) {
    $pdb = [System.IO.Path]::ChangeExtension($k.Path, ".pdb")
    if (-not (Test-Path $k.Path)) { $missing += $k.Name; continue }
    if (-not (Test-Path $pdb)) { $missing += "$($k.Name) -> missing $pdb" }
}

$pdbTotal = (Get-ChildItem -Path $InstallRoot -Filter *.pdb -Recurse).Count
Write-Host "PDB files under install: $pdbTotal"

if ($missing.Count -gt 0) {
    Write-Host "MISSING:" ($missing -join "; ")
    exit 1
}

foreach ($k in $keys) {
    $result = [ObsSymbolCheck]::CheckModule($InstallRoot, $k.Path)
    Write-Host "OK $($k.Name): $result"
}

Write-Host ""
Write-Host "Suggested _NT_SYMBOL_PATH:"
Write-Host "SRV*https://msdl.microsoft.com/download/symbols;$InstallRoot"