# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# January 4, 2012 | Soren Granfeldt
#	- initial version
# January 4, 2012 | Soren Granfeldt
#	- fixed bug with local SQL server
# January 4, 2012 | Soren Granfeldt
#	- adjusted settings to use virtual name from general settings instead of
#	- specifics from portal/srevice section
# January 9, 2012 | Soren Granfeldt
#	- changed $SHAREPOINT_URL and $SERVICEADDRESS to use virtual names instead of hostnames
# February 21, 2012 | Soren Granfeldt
#	- fixed problem with string calculation for SQLInstance

.\Common-InitializeScript.ps1

$SoftwarePath = "$($Settings.FIAB.General.SoftwareRootPath)"
$MsiFile = Join-Path $SoftwarePath "FIM\Service and Portal\Service and Portal.msi"
$LogFile = Join-Path "$PWD" "Logs\FIMServiceAndPortal.Installation.log"

if (Test-Path $LogFile) {Remove-Item $LogFile}

if (($Settings.FIAB.SQLServer.UseLocalSQLServer) -eq $False)
{
	if ($Settings.FIAB.SQLServer.SQLServer) { $SQLServer = "SQLSERVER_SERVER=$($Settings.FIAB.SQLServer.SQLServer)" }
	if ($Settings.FIAB.SQLServer.SQLServerInstance) { $SQLInstance = "$($Settings.FIAB.SQLServer.SQLServerInstance)" }
}

# Make sure that we have a SQL server name (and optionally an instance, since this is a required parameter
if ($SQLServer) 
{
	$SQLServer = ("$SQLServer\$SQLInstance").Trim('\') 
} 
else 
{
	$SQLServer = ("SQLSERVER_SERVER=$Hostname\$SQLInstance").Trim('\') 
}

$ACCEPT_EULA = "ACCEPT_EULA=1"
$SQMOPTINSETTING = "SQMOPTINSETTING=0"
$EXISTINGDATABASE = "EXISTINGDATABASE=0"
$SQLSERVER_DATABASE = "SQLSERVER_DATABASE=FIMService" # Do not change this default name
$SERVICE_ACCOUNT_NAME = "SERVICE_ACCOUNT_NAME=$($Settings.FIAB.General.ServiceAccounts.FIMService)" -Replace '.+=$',''
$SERVICE_ACCOUNT_PASSWORD = "SERVICE_ACCOUNT_PASSWORD=$($Settings.FIAB.General.ServiceAccounts.FIMServicePassword)" -Replace '.+=$',''
$SERVICE_ACCOUNT_DOMAIN = "SERVICE_ACCOUNT_DOMAIN=$DomainNetBIOSName" -Replace '.+=$',''
$SERVICE_ACCOUNT_EMAIL = "SERVICE_ACCOUNT_EMAIL=$($Settings.FIAB.General.ServiceAccounts.FIMServiceEMail)" -Replace '.+=$',''
$SYNCHRONIZATION_SERVER_ACCOUNT = "SYNCHRONIZATION_SERVER_ACCOUNT=$DomainNetBIOSName\$($Settings.FIAB.General.ServiceAccounts.ManagementAgentFIM)" -Replace '.+=$',''
$CERTIFICATE_NAME = "CERTIFICATE_NAME=ForefrontIdentityManager" # Do not change this default name
$MAIL_SERVER = "MAIL_SERVER=$($Settings.FIAB.FIMServiceAndFIMPortal.MailServer)" -Replace '.+=$',''
$MAIL_SERVER_IS_EXCHANGE = "MAIL_SERVER_IS_EXCHANGE=$([byte] $Settings.FIAB.FIMServiceAndFIMPortal.MailServerIsExchange)" -Replace '.+=$',''
$MAIL_SERVER_USE_SSL = "MAIL_SERVER_USE_SSL=$([byte] $Settings.FIAB.FIMServiceAndFIMPortal.MailServerUseSSL)" -Replace '.+=$',''
$POLL_EXCHANGE_ENABLED = "POLL_EXCHANGE_ENABLED=$([byte] $Settings.FIAB.FIMServiceAndFIMPortal.PollExchangeEnabled)" -Replace '.+=$',''
$SYNCHRONIZATION_SERVER = "SYNCHRONIZATION_SERVER=$($Settings.FIAB.FIMServiceAndFIMPortal.SynchronizationServer)" -Replace '.+=$',''

#$SERVICEADDRESS = "SERVICEADDRESS=$($Settings.FIAB.FIMServiceAndFIMPortal.ServiceAddress)" -Replace '.+=$',''
$SERVICEADDRESS = "SERVICEADDRESS=$($Settings.FIAB.General.QualifiedServiceVirtualName)" -Replace '.+=$',''

#$SHAREPOINT_URL = "SHAREPOINT_URL=$($Settings.FIAB.FIMServiceAndFIMPortal.SharePointUrl)" -Replace '.+=$',''
$SHAREPOINT_URL = "SHAREPOINT_URL=http://$($Settings.FIAB.General.QualifiedPortalVirtualName)" -Replace '.+=$',''

$FIREWALL_CONF = "FIREWALL_CONF=$([byte] $Settings.FIAB.FIMServiceAndFIMPortal.FirewallConfiguration)" -Replace '.+=$',''
$SHAREPOINTUSERS_CONF = "SHAREPOINTUSERS_CONF=$([byte] $Settings.FIAB.FIMServiceAndFIMPortal.SharePointUsersConfiguration)" -Replace '.+=$','' #Add authenticated users to SharePoint
$PASSWORDUSERS_CONF = "PASSWORDUSERS_CONF=$([byte] $Settings.FIAB.FIMServiceAndFIMPortal.PasswordPortalConfiguration)" -Replace '.+=$','' #Add authenticated users to Password Reset Portal
$SHAREPOINTTIMEOUT = "SHAREPOINTTIMEOUT=$($Settings.FIAB.FIMServiceAndFIMPortal.SharePointTimeout)" -Replace '.+=$','' # Timeout in seconds the installer should wait for Office SharePoint to deploy the solution packs.

$Arguments = "/LV $LogFile /qb /i ""$MsiFile"" $SQLServer $ACCEPT_EULA $SQMOPTINSETTING $EXISTINGDATABASE $SQLSERVER_DATABASE $SERVICE_ACCOUNT_NAME $SERVICE_ACCOUNT_PASSWORD $SERVICE_ACCOUNT_DOMAIN $SERVICE_ACCOUNT_EMAIL $SYNCHRONIZATION_SERVER_ACCOUNT $CERTIFICATE_NAME $MAIL_SERVER $MAIL_SERVER_IS_EXCHANGE $MAIL_SERVER_USE_SSL $POLL_EXCHANGE_ENABLED $SYNCHRONIZATION_SERVER $SERVICEADDRESS $SHAREPOINT_URL $FIREWALL_CONF $SHAREPOINTUSERS_CONF $PASSWORDUSERS_CONF $SHAREPOINTTIMEOUT"

Write-Host "Installing FIM Service and Portal using this command-line`r`n"
Write-Host "Command-line: $Arguments"

Start-Process -FilePath MSIEXEC.EXE -ArgumentList $Arguments -Wait

Write-Host "`r`nInstallation complete"

.\Common-TerminateScript.ps1