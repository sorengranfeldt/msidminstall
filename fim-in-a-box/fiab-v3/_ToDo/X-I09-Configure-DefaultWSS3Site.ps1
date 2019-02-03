# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# December 15, 2011 | Soren Granfeldt
#	- initial version
# January 6, 2011 | Soren Granfeldt
#	- some parts are based on http://sharepointforum.com/en-US/Wiki/Installation%20WSS%203.0.aspx
#	- changed to accommodate using SQL 2008 (R2) server instead of MSDE
#	- if you want to use MSDE, all other commands in this script can be replaced by one line (below)
#	  & "$CommonProgramFiles\Microsoft Shared\Web Server Extensions\12\BIN\PSCONFIG.EXE" -Cmd StandAloneConfig
# January 10, 2011 | Soren Granfeldt
#	- changed step to create and add alternate access mappings and rename default web based on
#	  http://blog.msresource.net/2011/06/06/how-to-setup-a-load-balanced-fim-portal-and-service-deployment/
#	- removed the parameter -ExclusivelyUseNTLM from step 3 to enable Kerberos instead of NTLM

param (
	[switch] $All = $false,
	[switch] $Step1CreateDatabases = $false,
	[switch] $Step2ProvisionCentralAdministrationSite = $false,
	[switch] $Step3CreateWebApplication = $false,
	[switch] $Step4ResetInternetInformationServer = $false,
	[switch] $Step5CreateDefaultSite = $false,
	[switch] $Step6ConfigureAlternateAccessMappings = $false
)
.\Common-InitializeScript.ps1

Write-Host "Configuring SharePoint Services - please wait..."
$CommonProgramFiles = $Env:CommonProgramFiles
$SQLServer = "$($Settings.FIAB.SQLServer.SQLServer)\$($Settings.FIAB.SQLServer.SQLServerInstance)" -Replace '\\$', ''
$AdminContentDatabase = $Settings.FIAB.SharePoint.DatabaseNameAdminContent
$ConfigurationDatabase = $Settings.FIAB.SharePoint.DatabaseNameConfiguration
$ContentDatabase = $Settings.FIAB.SharePoint.DatabaseNameContent

$SharePointConfigService = "$DomainNetBIOSName\$($Settings.FIAB.General.ServiceAccounts.SharePointConfigService)"
$SharePointConfigServicePassword = $Settings.FIAB.General.ServiceAccounts.SharePointConfigServicePassword

$SharePointAppPoolService = $Settings.FIAB.General.ServiceAccounts.SharePointApplicationPoolService
$SharePointAppPoolServicePassword = $Settings.FIAB.General.ServiceAccounts.SharePointApplicationPoolServicePassword

$AdminSitePortNumber = $Settings.FIAB.SharePoint.CentralAdministrationWebsitePortNumber
$OwnerLogin = "$DomainNetBIOSName\$($Settings.FIAB.SharePoint.SiteOwnerAccountName)"
$OwnerEMail = $Settings.FIAB.SharePoint.SiteOwnerEMail

$UnqualifiedPortalVirtualName = "http://$($Settings.FIAB.General.UnqualifiedPortalVirtualName)"
$QualifiedPortalVirtualName = "http://$($Settings.FIAB.General.QualifiedPortalVirtualName)"

$Url = "http://$($Hostname):80/"
$SiteTemplate = "STS#1"
$DefaultSiteTitle = "Default Site"

if ($Step1CreateDatabases -or $All)
{
	Write-host "Create initial databases on $SQLServer..."
	& "$CommonProgramFiles\Microsoft Shared\Web Server Extensions\12\BIN\PSCONFIG.EXE" -Cmd ConfigDB -Create -Server $SQLServer -User $SharePointConfigService -Password $SharePointConfigServicePassword -Database $ConfigurationDatabase -AdminContentDatabase $AdminContentDatabase
}	

if ($Step2ProvisionCentralAdministrationSite -or $All)
{
	Write-Host "Create Central Administration Website..."
	& "$CommonProgramFiles\Microsoft Shared\Web Server Extensions\12\BIN\PSCONFIG.EXE" -Cmd AdminVS -Provision -Port $AdminSitePortNumber -WindowsAuthProvider OnlyUseNTLM
}

if ($Step3CreateWebApplication -or $All)
{
	Write-Host "Creating Web Application ($Url)..."
	# DO NOT USE -DatabaseUser and -DatabasePassword parameters, since these are associated with SQL login and not Integrated Login
	# & "$CommonProgramFiles\Microsoft Shared\Web Server Extensions\12\BIN\STSADM.EXE" -o ExtendVS -Url $Url -OwnerEmail $OwnerEMail -ExclusivelyUseNTLM -OwnerLogin $OwnerLogin -DatabaseName $ContentDatabase -DatabaseServer $SQLServer -APIDName "FIMSharePoint - 80" -APIDType ConfigurableID -APIDLogin $SharePointAppPoolService -APIDPwd $SharePointAppPoolServicePassword -AllowAnonymous -DoNotCreateSite
	& "$CommonProgramFiles\Microsoft Shared\Web Server Extensions\12\BIN\STSADM.EXE" -o ExtendVS -Url $Url -OwnerEmail $OwnerEMail -OwnerLogin $OwnerLogin -DatabaseName $ContentDatabase -DatabaseServer $SQLServer -APIDName "FIMSharePoint - 80" -APIDType ConfigurableID -APIDLogin $SharePointAppPoolService -APIDPwd $SharePointAppPoolServicePassword -AllowAnonymous -DoNotCreateSite
}

if ($Step4ResetInternetInformationServer -or $All)
{
	Write-Host "Resetting Internet Information Server..."
	IISRESET /NoForce
}

if ($Step5CreateDefaultSite -or $All)
{
	Write-Host "Creating default site..."
	& "$CommonProgramFiles\Microsoft Shared\Web Server Extensions\12\BIN\STSADM.EXE" -o CreateSite -Url $Url -OwnerLogin $OwnerLogin -OwnerEmail $OwnerEMail -SiteTemplate $SiteTemplate -Title $DefaultSiteTitle
}

if ($Step6ConfigureAlternateAccessMappings -or $All)
{
	Write-Host "Adding http://localhost to Intranet Zone..."
	& "$CommonProgramFiles\Microsoft Shared\Web Server Extensions\12\BIN\STSADM.EXE" -o AddZoneUrl -Url $Url -UrlZone Intranet -ZoneMappedUrl http://localhost
	
	Write-Host "Adding Internal Url $UnqualifiedPortalVirtualName"
	& "$CommonProgramFiles\Microsoft Shared\Web Server Extensions\12\BIN\STSADM.EXE" -o AddAlternateDomain -IncomingUrl $UnqualifiedPortalVirtualName -Url $Url -UrlZone Default	

	Write-Host "Adding Internal Url http://$DnsHostname"
	& "$CommonProgramFiles\Microsoft Shared\Web Server Extensions\12\BIN\STSADM.EXE" -o AddAlternateDomain -IncomingUrl "http://$DnsHostname" -Url $Url -UrlZone Default	

	Write-Host "Changing Default url to $QualifiedPortalVirtualName"
	& "$CommonProgramFiles\Microsoft Shared\Web Server Extensions\12\BIN\STSADM.EXE" -o AddZoneUrl -Url $Url -UrlZone Default -ZoneMappedUrl $QualifiedPortalVirtualName

	Write-Host "Adding Internal Url http://$Hostname"
	& "$CommonProgramFiles\Microsoft Shared\Web Server Extensions\12\BIN\STSADM.EXE" -o AddAlternateDomain -IncomingUrl "http://$Hostname" -Url $QualifiedPortalVirtualName -UrlZone Default	
	
	Write-Host "Resetting Internet Information Server..."
	IISRESET /NoForce
}
.\Common-TerminateScript.ps1