$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
function Run-Step([scriptblock]$Command) {
  & $Command
  if ($LASTEXITCODE -ne 0) { throw "Release step failed with exit code $LASTEXITCODE" }
}
Run-Step { flutter pub get --enforce-lockfile }
Run-Step { flutter analyze }
Run-Step { flutter test --concurrency=1 }
Run-Step { flutter build windows --release }
# Bundle the app-local MSVC runtime so a clean offline Windows computer does
# not need to download the Visual C++ redistributable before starting RPM.
$ReleaseDirectory = 'build/windows/x64/runner/Release'
$VSWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (!(Test-Path $VSWhere)) { throw 'Visual Studio Installer/vswhere is required to locate the redistributable runtime.' }
$VSInstall = & $VSWhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if ($LASTEXITCODE -ne 0 -or !$VSInstall) { throw 'Could not locate the Visual Studio C++ installation.' }
# Match the desktop x64 CRT under a version-named folder (…/<version>/x64/Microsoft.VC###.CRT).
# Newer Visual Studio layouts also ship an 'onecore' variant whose grandparent folder is not a
# version string; exclude it so the [Version] sort below never sees a non-version name.
$CRTDirectory = Get-ChildItem (Join-Path $VSInstall 'VC/Redist/MSVC') -Recurse -Directory |
  Where-Object { $_.FullName -match '[\\/]x64[\\/]Microsoft\.VC[0-9]+\.CRT$' -and $_.Parent.Parent.Name -match '^\d+\.\d+' } |
  Sort-Object { [Version]$_.Parent.Parent.Name } -Descending | Select-Object -First 1
if (!$CRTDirectory) { throw 'Could not locate the x64 app-local MSVC runtime. Offline packaging has stopped.' }
Copy-Item (Join-Path $CRTDirectory.FullName '*.dll') $ReleaseDirectory -Force
foreach ($RuntimeFile in @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')) {
  if (!(Test-Path (Join-Path $ReleaseDirectory $RuntimeFile))) { throw "Missing offline runtime: $RuntimeFile" }
}
New-Item -ItemType Directory -Force -Path dist | Out-Null
Compress-Archive -Path 'build/windows/x64/runner/Release/*' -DestinationPath 'dist/RPM-Windows-x64.zip' -Force
$CompilerPath = (Get-Command ISCC.exe -ErrorAction SilentlyContinue).Source
if (!$CompilerPath) {
  $Candidate = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
  if (Test-Path $Candidate) { $CompilerPath = $Candidate }
}
if ($CompilerPath) {
  & $CompilerPath 'packaging/rpm.iss'
  if ($LASTEXITCODE -ne 0) { throw 'Installer compilation failed' }
} else {
  Write-Warning 'Portable ZIP built. Install Inno Setup 6 to also build the Windows installer.'
}
Get-ChildItem dist -File | Where-Object { $_.Extension -in '.zip', '.exe' } | ForEach-Object {
  $Hash = Get-FileHash $_.FullName -Algorithm SHA256
  "$($Hash.Hash.ToLower())  $($_.Name)" | Set-Content "$($_.FullName).sha256"
}
