<#
.SYNOPSIS
  Script for removing terminated users from Active Directory. Only requires username and script does the rest. Also creates a record of users group
  memberships on Domain Controller for records purposes.

.DESCRIPTION
  Does the following:
    -Creates a remote session with [DOMAIN CONTROLLER] (all following commands run are invoked on the remote machine to avoid a deserialized object type.)
    -Requests admin input for user name and stores as variable, uses this input to generate other variables used in the script.
    -Creates a CSV of user information, specifically groups, and exports it to \\[DOMAIN CONTROLLER]\C$\USER DATA.
    -Disables user account.
    -Moves user account to Terms OU.
    -Appends the date account was disabled to the account description.
    -Removes all groups from the user except for Domain Users.
    -Closes remote session with [DOMAIN CONTROLLER].

.NOTES
  Name: termUser.ps1
  Author: D. O'Neil
  Version: 1.1
  DateCreated: Nov 2023
#>

$s = New-PSSession -ComputerName [DOMAIN CONTROLLER]
Write-Host "Connected to [DOMAIN CONTROLLER]"

Invoke-Command -session $s -ScriptBlock {
    $account = Read-Host "Enter account name."
    $user = Get-ADUser -identity $account -properties *
    $filename = $user.Name
    $outfile = "C:\USER DATA\$filename.csv"
    $usergroups = Get-ADPrincipalGroupMembership -Identity $account

    #create array and export csv file

    $properties = @{
        Name = $user.name
        Title = $user.Title
        Department = $user.Department
        GroupName = $usergroups.Name -join [System.Environment]::NewLine
        }

    $Properties | Select-Object Name,Title,Department,GroupName | Export-CSV -NoTypeInformation -Path $outfile

    #disable user AD account

    Get-ADUser $account | Disable-ADAccount

    #append account description to date disabled

    Get-ADUser $account -properties description | Foreach-Object { Set-ADUser $_ -Description "$($_.description)(Disabled $(Get-Date -Format "MM/dd/yyyy"))" }

    #move AD account to Terms OU

    Get-ADUser $account | Move-ADObject -TargetPath "OU=Terms,OU=[],OU=[],DC=[],DC=[],DC=[]"

    #remove account from all Security Groups except Domain Users

    Get-ADGroup -Filter 'GroupCategory -eq "Security" -and Name -ne "Domain Users"' | Remove-ADGroupMember -Member $account -Confirm:$false
    }

Disconnect-PSSession -Session $s
