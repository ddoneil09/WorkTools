<#.
.SYNOPSIS
Script for quarterly user audit. Generates a CSV file of all active users with limited data for all.

.NOTES
You can adjust the file output location by adjusting the $path variable.

Name: auditADUsers.ps1
Author: Dan O'Neil
Version: 1.0
DateCreated: September 2023
#>

$path = "C:\temp\aduseraudit.csv"
Get-ADUser -Properties Name,Title,UserPrincipalName,department -Filter * -SearchBase "OU=Users,OU=Seaport,DC=bos,DC=seaporthotel,DC=com" | Where-Object {$_.Enabled -eq $true} | Export-Csv -path $path
