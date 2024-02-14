#Connect to Microsoft Graph
#See Microsoft documentation to enable unattended Graph logins: https://learn.microsoft.com/en-us/powershell/microsoftgraph/app-only?view=graph-powershell-1.0#see-also
Write-Host "Connecting to Microsoft Graph..." -ForegroundColor DarkYellow
Connect-MgGraph -ClientID <# Client ID #> -TenantId <# Tenant ID #> -CertificateName <# Cert Name #>
