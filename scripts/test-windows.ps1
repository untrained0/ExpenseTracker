# Runs the platform-independent logic tests on Windows (see Package.swift).
#
# Usage (from the repo root, in any PowerShell window):
#   .\scripts\test-windows.ps1
#
# Swift on Windows needs the MSVC linker (link.exe), so this loads the
# Visual Studio developer environment first. It also reloads PATH and SDKROOT,
# which covers terminals that were opened before Swift was installed.
$ErrorActionPreference = "Stop"

foreach ($scope in "Machine", "User") {
    foreach ($kv in [Environment]::GetEnvironmentVariables($scope).GetEnumerator()) {
        if ($kv.Key -ne "Path") { Set-Item -Path "Env:$($kv.Key)" -Value $kv.Value }
    }
}
$env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
            [Environment]::GetEnvironmentVariable("Path", "User")

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) {
    throw "Visual Studio Build Tools not found. Install them with the C++ (MSVC x64) and Windows SDK components."
}
$vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
Import-Module "$vs\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
Enter-VsDevShell -VsInstallPath $vs -SkipAutomaticLocation -DevCmdArguments "-arch=x64 -host_arch=x64" 2>$null | Out-Null

Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    swift test @args
    exit $LASTEXITCODE
} finally {
    Pop-Location
}
