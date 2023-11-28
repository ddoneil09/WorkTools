<#
.SYNOPSIS
  Creates a new user in Active Directory, add them to groups, and license their account.

.DESCRIPTION
  This script will request new user information which needs to be filled out by the admin. It will then create a new Active Directory user and assign
  it to standard groups or copy groups from a specific user. It will then initiate an Azure Active Directory Sync to populate the new user in Azure.
  Then the script will connect to Microsoft Graph API, update the new user, and assign it a license (which creates the user's mailbox). Then it
  disconnects from Graph and exits the script.

.NOTES 
  In order for this to run on your machine, you need to configure unattended Microsoft Graph logins. It is noted where this is necessary in the script.
  See the follow for more information: https://learn.microsoft.com/en-us/powershell/microsoftgraph/app-only?view=graph-powershell-1.0#see-also
  
.NOTES
  Name: newUser.ps1
  Author: D. O'Neil
  Version: 1.0
  DateCreated: Nov 2023
#>

Write-Host "###################################" -ForegroundColor DarkYellow
Write-Host "### NEW USER CREATION INITIATED ###" -ForegroundColor DarkYellow
Write-Host "###################################" -ForegroundColor DarkYellow

#obtain necessary user information and set variables (you could also set this up to pull from a CSV)

$firstname = Read-Host "Enter the first name of the mailbox user"
$lastname = Read-Host "Enter the last name of the mailbox user"
$username = Read-Host "Enter the user's username" #SamAccountName
$department = Read-Host "Which department is the user in?"
$title = Read-Host "What is the user's job title?"
$manager = Read-Host "What is the manager's username?" # SamAccountName
$UPN = "$firstname.$lastname@yourdomain.com"
$password = ConvertTo-SecureString "Password1234!" -AsPlainText #this is fine in plain text as it will be changed on first login

#define AD parameters and create the user in AD

$userSplat = @{
    AccountPassword = $password
    ChangePasswordAtLogon = $true
    City = "City"
    Company = "Company"
    Country = "Country"
    Department = $department
    Description = $title
    DisplayName = "$lastname, $firstname"
    EmailAddress = $UPN
    Enabled = $true
    GivenName = $firstname
    Name = "$lastname, $firstname"
    Path = "OU=[],OU=[],DC=[],DC=[],DC=[]"
    PostalCode = "ZIP"
    SamAccountName = $username
    State = "State"
    Surname = $lastname
    StreetAddress = "Street Address"
    Title = $title
    UserPrincipalName = $UPN
}

if ($manager) { 
    $userSplat.manager = $manager}

Write-Host "Creating new user in Active Directory..." -ForegroundColor DarkYellow
New-ADUser @userSplat

$groupSplat = @{
    Identity = "$username"
    MemberOf = @(
        "SG-1",
        "SG-2",
        "SG-3"
    )
}

$sgcopy = "Do you want to copy another user's groups to this account? y/n"
    do {
        $sgcopy = Read-Host -Prompt $sgcopy
        if ($sgcopy -like "y*") {
            $copyuser = Read-Host "Please enter the username you would like to copy FROM";
            Get-ADUser -Identity $copyuser -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $username -PassThru;
            $sgcopy = 'n' 
        }
    } until ($sgcopy -like "n*")

Write-Host "Adding baseline group memberships..." -ForegroundColor DarkYellow
Add-ADPrincipalGroupMembership @groupSplat

#forces ADSync to run to minimize time for user to appear in M365
Write-Host "Syncing AAD Connect..." -ForegroundColor DarkYellow
$s = New-PSSession -ComputerName [SERVER-NAME]
Invoke-Command -Session $s -ScriptBlock { Import-Module ADSync }
Invoke-Command -Session $s -ScriptBlock { Start-ADSyncSyncCycle -PolicyType Delta }

#Connect to Microsoft Graph
#See Microsoft documentation if using on a machine other than Dan's to enable unattended Graph logins: https://learn.microsoft.com/en-us/powershell/microsoftgraph/app-only?view=graph-powershell-1.0#see-also
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor DarkYellow
Connect-MgGraph -NoWelcome -ClientID "683f2b2f-abbd-469f-92e5-086cc2a297b5" -TenantId "ce806cf2-2533-48e4-9bf9-eedf6e3e22d1" -CertificateName "CN=GraphCert"

#Get additional variables from Microsoft Graph
$SkuID = Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq 'SPE_E3' #or whatever

#Splat for Update-MGUser
$cloudUserSplat = @{
    UserId = $UPN
    AccountEnabled = $true
    UsageLocation = "US" #you need this to assign license
}

#loops until Update-MGuser is successful, then continues 
function Start-Loop {
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$Command,
        
        [int]$MaxAttempts = 100,
        
        [int]$DelaySeconds = 5
    )
    
    $attempt = 1
    
    while ($attempt -le $MaxAttempts) {
        try {
            Write-Host "Updating Cloud Account............. (Attempt: $attempt)" -ForegroundColor Blue
            & $Command
            
            # Command executed successfully, exit the loop
            return
        }
        catch {
            Write-Host "Cloud account does not exist yet... (Attempt: $attempt)" -ForegroundColor Yellow
            
            # Increment the attempt counter
            $attempt++
            
            # Delay before the next attempt
            Start-Sleep -Seconds $DelaySeconds
        }
    }
    
    Write-Host "Updating the cloud account failed after $MaxAttempts attempts"
}

Start-Loop -Command { Update-MgUser @cloudUserSplat -ErrorAction Stop }

#Add license
Set-MgUserLicense -UserId $UPN -AddLicenses @{SkuId = $SkuID.SkuId} -RemoveLicenses @()

#Disconnect from MgGraph
Disconnect-MgGraph

Write-Host "New account created and licensed!" -ForegroundColor DarkYellow
