<#
.SYNOPSIS
Enables Bitlocker on a workstation that does not have it, and saves the key to Active Directory.

.NOTES
Name: bitlock.ps1
Author: Dan O'Neil
Version: 1.0
#>

#generates key if one does not exist
$keyID = Get-BitLockerVolume -MountPoint c: | Select-Object -ExpandProperty keyprotector | 
            Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'} #captures key

If ($keyID -eq $Null) {
    cmd /c manage-bde.exe -protectors -add c: -recoverypassword #generates a Numerical Password
    $keyID = Get-BitLockerVolume -MountPoint c: | Select-Object -ExpandProperty keyprotector | 
            Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'} #captures key
}

#enables Bitlocker and saves key to AD
Backup-BitLockerKeyProtector -MountPoint c: -KeyProtectorId $keyID.KeyProtectorId
Enable-BitLocker -MountPoint C: -SkipHardwareTest -RecoveryPasswordProtector -UsedSpaceOnly