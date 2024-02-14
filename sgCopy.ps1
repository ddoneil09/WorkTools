<#
.SYNOPSIS
  Quick script to copy one user's group memberships to another user. Uses terminal input from admin.

.NOTES
  Name: sgCopy.ps1
  Author: D. O'Neil
  Version: 1.0
  DateCreated: May 2023
#>

#these take sAMAccountName
$copyuser = Read-Host "Enter user you wish to copy FROM"
$pasteuser = Read-Host "Enter user you wish to copy TO"

Get-ADUser -Identity $copyuser -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $pasteuser -PassThru | Out-Null

Write-Host "$pasteuser now has the same groups as $copyuser"
