<#
.SYNOPSIS
    Automated installation of development tools, utilities, and system configuration on Windows 10
.DESCRIPTION
    This script installs Python 2.7, Python 3.x, various development tools, configures Windows Defender settings,
    changes the desktop background, and installs Python packages via pip.
.NOTES
    File Name      : Install-DevTools-Advanced.ps1
    Requires Admin : Yes
    Author         : AI Assistant
    Version        : 2.0
#>

# Require admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires administrator privileges. Please run as administrator." -ForegroundColor Red
    exit
}

# Set execution policy to allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

# Create a temporary directory for downloads
$downloadDir = "$env:TEMP\SoftwareInstall"
if (!(Test-Path -Path $downloadDir)) {
    New-Item -ItemType Directory -Path $downloadDir | Out-Null
}

# Function to download and install software
function Install-Software {
    param(
        [string]$SoftwareName,
        [string]$DownloadUrl,
        [string]$InstallerPath,
        [string]$InstallArgs,
        [string]$InstallerType = "exe"
    )
    
    Write-Host "Downloading $SoftwareName..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        Write-Host "Installing $SoftwareName..." -ForegroundColor Cyan
        
        if ($InstallerType -eq "exe") {
            Start-Process -FilePath $InstallerPath -ArgumentList $InstallArgs -Wait -NoNewWindow
        }
        elseif ($InstallerType -eq "msi") {
            Start-Process msiexec.exe -Wait -ArgumentList "/i `"$InstallerPath`" $InstallArgs"
        }
        
        Write-Host "$SoftwareName installed successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Failed to install $SoftwareName`: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Function to install Python packages
function Install-PythonPackages {
    param(
        [string]$PythonExecutable,
        [string[]]$Packages
    )
    
    Write-Host "Installing Python packages for $PythonExecutable..." -ForegroundColor Cyan
    foreach ($package in $Packages) {
        try {
            Write-Host "Installing $package..." -ForegroundColor Cyan
            Start-Process -FilePath $PythonExecutable -ArgumentList "-m pip install $package" -Wait -NoNewWindow
            Write-Host "Successfully installed $package" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to install $package`: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Function to disable Windows Defender
function Disable-WindowsDefender {
    Write-Host "Configuring Windows Defender settings..." -ForegroundColor Cyan
    
    try {
        # Disable real-time monitoring
        Set-MpPreference -DisableRealtimeMonitoring $true
        Write-Host "Disabled real-time monitoring" -ForegroundColor Green
        
        # Disable behavior monitoring
        Set-MpPreference -DisableBehaviorMonitoring $true
        Write-Host "Disabled behavior monitoring" -ForegroundColor Green
        
        # Disable intrusion prevention
        Set-MpPreference -DisableIntrusionPreventionSystem $true
        Write-Host "Disabled intrusion prevention" -ForegroundColor Green
        
        # Disable IOAV protection
        Set-MpPreference -DisableIOAVProtection $true
        Write-Host "Disabled IOAV protection" -ForegroundColor Green
        
        # Disable script scanning
        Set-MpPreference -DisableScriptScanning $true
        Write-Host "Disabled script scanning" -ForegroundColor Green
        
        # Add exclusions for common development directories
        $exclusionPaths = @(
            "${env:ProgramFiles}\Python27",
            "${env:ProgramFiles}\Python312",
            "${env:USERPROFILE}\AppData\Local\Programs\Python",
            "C:\Tools",
            "${env:USERPROFILE}\Documents\GitHub"
        )
        
        foreach ($path in $exclusionPaths) {
            if (Test-Path $path) {
                Add-MpPreference -ExclusionPath $path
                Write-Host "Added exclusion for $path" -ForegroundColor Green
            }
        }
        
        Write-Host "Windows Defender has been configured for development work" -ForegroundColor Green
    }
    catch {
        Write-Host "Error configuring Windows Defender: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to set desktop background
function Set-DesktopBackground {
    param(
        [string]$ImageUrl
    )
    
    Write-Host "Setting desktop background..." -ForegroundColor Cyan
    
    try {
        $backgroundPath = "$env:TEMP\wallpaper.jpg"
        
        # Download the image
        Invoke-WebRequest -Uri $ImageUrl -OutFile $backgroundPath -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        
        # Set the desktop background
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
        Write-Host "Desktop background changed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to set desktop background: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Install Python 2.7
$python2Url = "https://www.python.org/ftp/python/2.7.18/python-2.7.18.amd64.msi"
$python2Installer = "$downloadDir\python-2.7.msi"
Install-Software -SoftwareName "Python 2.7" -DownloadUrl $python2Url -InstallerPath $python2Installer -InstallArgs "/quiet ADDLOCAL=ALL ALLUSERS=1" -InstallerType "msi"

# Install Python 3.x (latest stable)
$python3Url = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"
$python3Installer = "$downloadDir\python-3.x.exe"
Install-Software -SoftwareName "Python 3.x" -DownloadUrl $python3Url -InstallerPath $python3Installer -InstallArgs "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0"

# Install Sublime Text
$sublimeUrl = "https://download.sublimetext.com/sublime_text_build_4152_x64_setup.exe"
$sublimeInstaller = "$downloadDir\sublime-text.exe"
Install-Software -SoftwareName "Sublime Text" -DownloadUrl $sublimeUrl -InstallerPath $sublimeInstaller -InstallArgs "/S"

# Install Notepad++
$nppUrl = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.5.4/npp.8.5.4.Installer.x64.exe"
$nppInstaller = "$downloadDir\npp-installer.exe"
Install-Software -SoftwareName "Notepad++" -DownloadUrl $nppUrl -InstallerPath $nppInstaller -InstallArgs "/S"

# Install WinRAR
$winrarUrl = "https://www.win-rar.com/fileadmin/winrar-versions/winrar/winrar-x64-623.exe"
$winrarInstaller = "$downloadDir\winrar.exe"
Install-Software -SoftwareName "WinRAR" -DownloadUrl $winrarUrl -InstallerPath $winrarInstaller -InstallArgs "/S"

# Install Telegram
$telegramUrl = "https://telegram.org/dl/desktop/win64"
$telegramInstaller = "$downloadDir\telegram.exe"
Install-Software -SoftwareName "Telegram" -DownloadUrl $telegramUrl -InstallerPath $telegramInstaller -InstallArgs "/silent"

# Install Brave Browser
$braveUrl = "https://laptop-updates.brave.com/latest/winx64"
$braveInstaller = "$downloadDir\brave.exe"
Install-Software -SoftwareName "Brave Browser" -DownloadUrl $braveUrl -InstallerPath $braveInstaller -InstallArgs "--silent --install"

# Install Strawberry Perl
$perlUrl = "https://strawberryperl.com/download/5.32.1.1/strawberry-perl-5.32.1.1-64bit.msi"
$perlInstaller = "$downloadDir\perl.msi"
Install-Software -SoftwareName "Perl" -DownloadUrl $perlUrl -InstallerPath $perlInstaller -InstallArgs "/quiet" -InstallerType "msi"

# Install GitHub Desktop
$githubUrl = "https://central.github.com/deployments/desktop/desktop/latest/win32"
$githubInstaller = "$downloadDir\github.exe"
Install-Software -SoftwareName "GitHub Desktop" -DownloadUrl $githubUrl -InstallerPath $githubInstaller -InstallArgs "--silent"

# Install Java JDK (Adoptium Temurin)
$javaUrl = "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.8%2B7/OpenJDK17U-jdk_x64_windows_hotspot_17.0.8_7.msi"
$javaInstaller = "$downloadDir\java-jdk.msi"
Install-Software -SoftwareName "Java JDK" -DownloadUrl $javaUrl -InstallerPath $javaInstaller -InstallArgs "/quiet" -InstallerType "msi"

# Install Wireshark
$wiresharkUrl = "https://2.na.dl.wireshark.org/win64/Wireshark-4.0.8-x64.exe"
$wiresharkInstaller = "$downloadDir\wireshark.exe"
Install-Software -SoftwareName "Wireshark" -DownloadUrl $wiresharkUrl -InstallerPath $wiresharkInstaller -InstallArgs "/S /desktopshortcut=0 /quicklaunchshortcut=0"

# Install Burp Suite Community Edition
$burpUrl = "https://portswigger-cdn.net/burp/releases/download?product=community&version=2023.10.3&type=WindowsX64"
$burpInstaller = "$downloadDir\burpsuite.exe"
Install-Software -SoftwareName "Burp Suite" -DownloadUrl $burpUrl -InstallerPath $burpInstaller -InstallArgs "-q"

# Disable Windows Defender
Disable-WindowsDefender

# Set desktop background
$wallpaperUrl = "https://images5.alphacoders.com/413/413842.jpg"
Set-DesktopBackground -ImageUrl $wallpaperUrl

# Install Python packages for both Python versions
$pythonPackages = @("colorama", "requests", "bs4", "lxml", "beautifulsoup4")

# Install packages for Python 2.7
if (Test-Path "${env:ProgramFiles}\Python27\python.exe") {
    Install-PythonPackages -PythonExecutable "${env:ProgramFiles}\Python27\python.exe" -Packages $pythonPackages
} else {
    Write-Host "Python 2.7 not found, skipping package installation" -ForegroundColor Red
}

# Install packages for Python 3.x
$python3Path = Get-Command python -ErrorAction SilentlyContinue
if ($python3Path) {
    Install-PythonPackages -PythonExecutable "python" -Packages $pythonPackages
} else {
    Write-Host "Python 3.x not found in PATH, skipping package installation" -ForegroundColor Red
}

# Verify installations
Write-Host "`nVerifying installations..." -ForegroundColor Yellow

$softwareList = @(
    @{Name="Python 2.7"; Path="${env:ProgramFiles}\Python27\python.exe"; Args="--version"},
    @{Name="Python 3.x"; Path="python"; Args="--version"},
    @{Name="Java JDK"; Path="${env:ProgramFiles}\Eclipse Adoptium\jdk-17.0.8.7-hotspot\bin\java.exe"; Args="-version"},
    @{Name="Wireshark"; Path="${env:ProgramFiles}\Wireshark\Wireshark.exe"; Args="--version"},
    @{Name="Perl"; Path="${env:ProgramFiles}\Strawberry\perl\bin\perl.exe"; Args="--version"}
)

foreach ($software in $softwareList) {
    try {
        if (Test-Path $software.Path) {
            $version = & $software.Path $software.Args 2>&1
            Write-Host "$($software.Name): $version" -ForegroundColor Green
        } else {
            # Try to find in PATH
            $found = Get-Command $software.Path -ErrorAction SilentlyContinue
            if ($found) {
                $version = & $software.Path $software.Args 2>&1
                Write-Host "$($software.Name): $version" -ForegroundColor Green
            } else {
                Write-Host "$($software.Name): Not found" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "$($software.Name): Error checking version" -ForegroundColor Red
    }
}

# Clean up
Write-Host "`nCleaning up temporary files..." -ForegroundColor Cyan
Remove-Item -Path $downloadDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`nInstallation and configuration process completed." -ForegroundColor Yellow
Write-Host "You may need to restart your system for all changes to take effect." -ForegroundColor Yellow

# Open installed applications in Start Menu
Write-Host "`nYou can now find the installed applications in your Start Menu." -ForegroundColor Cyan

# Final message
Write-Host @"

=== SUMMARY OF INSTALLATIONS ===
1. Python 2.7 and Python 3.x with pip packages:
   - colorama, requests, bs4, lxml, beautifulsoup4
2. Development Tools:
   - Sublime Text, Notepad++, WinRAR
3. Communication:
   - Telegram, Brave Browser
4. Security & Networking:
   - Wireshark, Burp Suite Community Edition
5. Programming Languages:
   - Perl, Java JDK
6. Utilities:
   - GitHub Desktop
7. System Configuration:
   - Windows Defender settings adjusted for development
   - Desktop background changed

Note: Some security features have been disabled for development purposes.
Consider re-enabling them when not doing development work.
"@ -ForegroundColor Magenta