<#
.SYNOPSIS
  Used to manually force a sync from Active Directory to Microsoft Entra ID. Doesn't work immediately, but usually syncs in under a minute.

.NOTES
  Name: syncAAD.ps1
  Author: D. O'Neil
  Version: 1.0
  DateCreated: Nov 2023
#>

Write-Host "Syncing AAD Connect..." -ForegroundColor DarkYellow
$s = New-PSSession -ComputerName SH-Util
Invoke-Command -Session $s -ScriptBlock { Import-Module ADSync }
Invoke-Command -Session $s -ScriptBlock { Start-ADSyncSyncCycle -PolicyType Delta }
