<#
.SYNOPSIS
Written to address the Cert Padding vulnerability.

.NOTES
Name: certPadding.ps1
Author: Dan O'Neil
Version: 1.0
DateCreated: November 2023
#>

if (-not(Test-Path -Path "HKLM:\Software\Microsoft\Cryptography\Wintrust\Config" -PathType Container)) {
    try {
        New-Item -Path HKLM:\Software\Microsoft\Cryptography\Wintrust\Config -ItemType Container -Force -ErrorAction Stop
        New-ItemProperty -Path HKLM:\Software\Microsoft\Cryptography\Wintrust\Config -Name EnableCertPaddingCheck -Value 1 -PropertyType String -ErrorAction Stop
        if ([System.Environment]::Is64BitOperatingSystem) {
            if (-not(Test-Path -Path "HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust\Config" -PathType Container)) {
                New-Item -Path HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust\Config -ItemType Container -Force -ErrorAction Stop
                New-ItemProperty -Path HKLM:\Software\Wow6432Node\Microsoft\Cryptography\Wintrust\Config -Name EnableCertPaddingCheck -Value 1 -PropertyType String -ErrorAction Stop
            }
        }
    } catch {
        Write-Warning -Message "Failed to create registry key because $($_.Exception.Message)"
    }
}
Get-Service -Name CryptSvc -Verbose | Stop-Service -Verbose -Force -PassThru | Start-Service -PassThru -Verbose