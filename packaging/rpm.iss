#define AppName "Receipts & Payments Manager"
#define AppVersion "1.1.0"
[Setup]
AppId={{286DB9DF-2BA4-42F9-9A89-21440199AF52}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=Hudeifa-janagale
AppCopyright=Copyright (C) 2026 Hudeifa-janagale. All rights reserved.
DefaultDirName={localappdata}\Programs\RPM
DefaultGroupName=RPM
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir=..\dist
OutputBaseFilename=RPM-Windows-x64-Setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\rpm.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\rpm.exe"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\rpm.exe"; Tasks: desktopicon
[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked
[Run]
Filename: "{app}\rpm.exe"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent
; User financial records in Documents/RPM are never part of uninstall.
