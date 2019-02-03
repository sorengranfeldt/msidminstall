# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# June 14, 2012 | Soren Granfeldt
#	- initial version of module

Write-Debug "Microsoft FIM-in-a-Box | System Center for People"
Write-Debug "(c) Copyright 2010-2012 Microsoft Corporation. All rights reserved.`r`n"

[XML] $Settings = Get-Content -Path FIAB.Settings.xml
$SoftwarePath = $Settings.FIAB.General.SoftwareRootPath

# OU's
$ManagedOU = $Settings.FIAB.General.ManagedOU
Write-Debug "Managed OU: $ManagedOU"
$ServiceAccountsOU = $Settings.FIAB.General.ServiceAccountsOU
Write-Debug "Service Account OU: $ServiceAccountOU"

# URL's
$PortalFQDN = $Settings.FIAB.General.QualifiedPortalVirtualName
$PortalNetBIOSName = $Settings.FIAB.General.UnqualifiedPortalVirtualName
$ServiceFQDN = $Settings.FIAB.General.QualifiedServiceVirtualName
$ServiceNetBIOSName = $Settings.FIAB.General.UnqualifiedServiceVirtualName
$PasswordResetFQDN = $Settings.FIAB.General.PasswordResetFQDN
$PasswordResetNetBIOSName = $Settings.FIAB.General.PasswordResetNetBIOSName
$PasswordRegistrationFQDN = $Settings.FIAB.General.PasswordRegistrationFQDN

# SQL Server
[bool] $UseLocalSqlServer = [int] $Settings.FIAB.SQLServer.UseLocalSQLServer
Write-Debug "Is Local SQL server: $UseLocalSqlServer"
$SQLServer = $Settings.FIAB.SQLServer.SQLServer
Write-Debug "SQL Server: $SqlServer"
$SQLInstance = $Settings.FIAB.SQLServer.SQLServerInstance
Write-Debug "SQL Server Instance: $SqlServerInstance"
$SQLServerWithInstance = "$SQLServer\$SQLInstance" -replace '\\$'
Write-Debug "SQL Server with Instance: $SqlServerWithInstance"
$SQLServerServiceAccount = $Settings.FIAB.General.ServiceAccounts.SQLServer
$SQLServerServiceAccountPassword = $Settings.FIAB.General.ServiceAccounts.SQLServerPassword
Write-Debug "SQL Server service account: $SQLServerServiceAccount"
$SQLServerAgentServiceAccount = $Settings.FIAB.General.ServiceAccounts.SQLServerAgent
$SQLServerAgentServiceAccountPassword = $Settings.FIAB.General.ServiceAccounts.SQLServerAgentPassword
Write-Debug "SQL Server service account: $SQLServerAgentServiceAccount"

"$SQLServer", "$ServiceNetBIOSName", "$ServiceFQDN", "$PortalFQDN", "$PortalNetBIOSName", "$PasswordResetFQDN", "$PasswordResetNetBIOSName", "$PasswordRegistrationFQDN" | foreach `
{
	$dnsEntry = $_
	Write-Progress -Id 1 -Activity "Verifing DNS record for" -status "$dnsEntry"
	try
	{
		$IpAddress = ([System.Net.Dns]::GetHostEntry($dnsEntry)).AddressList | ? {!$_.IsIPv6LinkLocal} | Select -Expand IPAddressToString
		Write-Debug "Resolved DNS record '$dnsEntry' to $IpAddress"
	}
	catch
	{
		[Exception]
		Write-Error "Cannot resolve DNS record for '$dnsEntry'. You may try to flush the DNS cache to eliminate negative DNS caching."
	}
}

$Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
Write-Debug "Current Domain: $Domain"

$RootDse = [ADSI] "LDAP://RootDSE"
$DefaultNamingContext = $RootDse.defaultNamingContext
Write-Debug "Default Naming Context: $DefaultNamingContext"
$ConfigurationNamingContext = $RootDse.configurationNamingContext
Write-Debug "Configuration Naming Context: $ConfigurationNamingContext"

# get the netbios name of the domain, since we can't assume that the current account is
# in the same domain as the computer we're running on
$Searcher = New-Object System.DirectoryServices.DirectorySearcher([ADSI] "LDAP://$ConfigurationNamingContext")
$Searcher.Filter = "(&(objectCategory=crossRef)(nCName=$DefaultNamingContext))"
$Searcher.PropertiesToLoad.Add("nETBIOSName")
$Results = $Searcher.FindOne()
if ($Results)
{
	$DomainNetBIOSName = $Results.Properties.Item("nETBIOSName")[0]
	Write-Debug "NetBIOS Domain: $DomainNetBIOSName"
}

$Username = (whoami).ToUpper()
$UsernameWithDomain = (whoami).ToUpper()
$ShortUsername = (whoami).ToUpper() -Replace "^.+\\"
$UsernameWithoutDomain = (whoami).ToUpper() -Replace "^.+\\"
$Hostname = (hostname).ToUpper()
$DnsHostname = ([System.Net.Dns]::GetHostEntry($hostname).HostName).ToLower()

# Management Agents
$MAADServiceAccount = $Settings.FIAB.General.ServiceAccounts.ManagementAgentAD 
Write-Debug "MA AD service account: $MAADServiceAccount"
$MAADServiceAccountPassword = $Settings.FIAB.General.ServiceAccounts.ManagementAgentADPassword
$MAFIMServiceAccount = $Settings.FIAB.General.ServiceAccounts.ManagementAgentFIM
Write-Debug "MA FIM service account: $MAFIMServiceAccount"
$MAFIMServiceAccountPassword = $Settings.FIAB.General.ServiceAccounts.ManagementAgentFIMPassword

# FIM Service and Portal
$FIMServiceServiceAccount = $Settings.FIAB.General.ServiceAccounts.FIMService 
Write-Debug "FIM Service service account: $FIMServiceServiceAccount"
$FIMServiceServiceAccountPassword = $Settings.FIAB.General.ServiceAccounts.FIMServicePassword

$FIMServiceServiceAccountEMail = $Settings.FIAB.General.ServiceAccounts.FIMServiceEMail
Write-Debug "FIM Service service account email: $FIMServiceServiceAccountEMail"

$MailServer = $Settings.FIAB.FIMServiceAndFIMPortal.MailServer
Write-Debug "Mail server: $MailServer"
$MailServerIsExchange = [int] $Settings.FIAB.FIMServiceAndFIMPortal.MailServerIsExchange
Write-Debug "Mail server is Exchange?: $MailServerIsExchange"
$MailServerUseSSL = [int] $Settings.FIAB.FIMServiceAndFIMPortal.MailServerUseSSL
Write-Debug "MailServer use SSL: $MailServerUseSSL"

# FIM Password Reset
$FIMPasswordResetServiceServiceAccount = $Settings.FIAB.General.ServiceAccounts.FIMPasswordResetService
Write-Debug "FIM Password Reset Service service account: $FIMPasswordResetServiceServiceAccount = "
$FIMPasswordResetServiceServiceAccountPassword = $Settings.FIAB.General.ServiceAccounts.FIMPasswordResetServicePassword

# FIM Synchronization Settings
$SyncServiceAccount = $Settings.FIAB.General.ServiceAccounts.FIMSynchronizationService
Write-Debug "Sync Service Account: $SyncServiceAccount"
$SyncServiceAccountPassword = $Settings.FIAB.General.ServiceAccounts.FIMSynchronizationServicePassword
Write-Debug "Sync Service Account Password: $SyncServiceAccountPassword"
$SyncGroupAdmins = "{0}\{1}" -F $DomainNetBIOSName, $Settings.FIAB.SynchronizationService.GroupAdmins
Write-Debug "Sync Group Admins: $SyncGroupAdmins"
$SyncGroupOperators = "{0}\{1}" -F $DomainNetBIOSName, $Settings.FIAB.SynchronizationService.GroupOperators
Write-Debug "Sync Group Operators: $SyncGroupOperators"
$SyncGroupAccountJoiners = "{0}\{1}" -F $DomainNetBIOSName, $Settings.FIAB.SynchronizationService.GroupAccountJoiners
Write-Debug "Sync Group Account Joiners: $SyncGroupAccountJoiners"
$SyncGroupBrowse = "{0}\{1}" -F $DomainNetBIOSName, $Settings.FIAB.SynchronizationService.GroupBrowse
Write-Debug "Sync Group Browse: $SyncGroupBrowse"
$SyncGroupPasswordSet = "{0}\{1}" -F $DomainNetBIOSName, $Settings.FIAB.SynchronizationService.GroupPasswordSet
Write-Debug "Sync Group Password Set: $SyncGroupPasswordSet"

# SharePoint Foundation 2010
$SPConfigurationDatabase = $Settings.FIAB.SharePoint2010.DatabaseConfiguration
Write-Debug "SP Configuration Database: $SPConfigurationDatabase"
$CentralAdminWebApplicationPortNumber = $Settings.FIAB.SharePoint2010.CentralAdminWebApplicationPortNumber #8080
Write-Debug "SP Central Admin Web Application Port Number: $CentralAdminWebApplicationPortNumber"
$SPAuthentication = $Settings.FIAB.SharePoint2010.Authentication
Write-Debug "SP Authentication Provider: $SPAuthentication"
$SPAdminContentDatabase = $Settings.FIAB.SharePoint2010.DatabaseAdminContent
Write-Debug "SP Administration Content Database Name: $SPAdminContentDatabase"
$SPFarmPassphrase = $Settings.FIAB.SharePoint2010.FarmPassphrase
Write-Debug "SP Passphrase: $SPFarmPassphrase"
$SPConfigServiceServiceAccount = $Settings.FIAB.General.ServiceAccounts.SharePointConfigService
Write-Debug "SP Configuration Service (service account): $SPConfigServiceServiceAccount"
$SPConfigServiceServiceAccountPassword = $Settings.FIAB.General.ServiceAccounts.SharePointConfigServicePassword
Write-Debug "SP Configuration Service (service account) password: $SPConfigServiceServiceAccountPassword"
$SPWebApplicationName = $Settings.FIAB.SharePoint2010.WebApplication
Write-Debug "SP Web Application name: $SPWebApplicationName"
$SPWebApplicationPort = $Settings.FIAB.SharePoint2010.WebApplicationPort
Write-Debug "SP Web Application port: $SPWebApplicationPort"
$WebApplicationAppPool = $Settings.FIAB.SharePoint2010.WebApplicationAppPool
Write-Debug "SP Web Application AppPool: $WebApplicationAppPool"
$SPAppPoolServiceAccount = "{0}\{1}" -F $DomainNetBiosName,$Settings.FIAB.General.ServiceAccounts.SharePointApplicationPoolService
Write-Debug "SP Web Application AppPool account: $SPAppPoolServiceAccount"
$SPAppPoolServiceAccountPassword = $Settings.FIAB.General.ServiceAccounts.SharePointApplicationPoolServicePassword
Write-Debug "SP Application Pool (service account) password: $SPAppPoolServiceAccountPassword"
$WebApplicationDatabaseName = $Settings.FIAB.SharePoint2010.DatabaseContent
Write-Debug "SP Web Application Content database: $WebApplicationDatabaseName"
$SPSiteCollectionName = $Settings.FIAB.SharePoint2010.SiteCollectionName #"FIM in-a-Box R2"
Write-Debug "SP Site Collection Name: $SPSiteCollectionName"
$SPSiteCollectionTemplate = $Settings.FIAB.SharePoint2010.SiteCollectionTemplate #"STS#0"
Write-Debug "SP Site Collection template: $SPSiteCollectionTemplate"
$SPSiteCollectionLanguage = $Settings.FIAB.SharePoint2010.SiteCollectionLanguage #1033
Write-Debug "SP Site Collection language: $SPSiteCollectionLanguage"
$SPSiteCollectionOwner = $UsernameWithDomain # we'll always set the primary owner to the user running the script; otherwise we may have trouble access the default site initially
Write-Debug "SP Site Collection owner: $SPSiteCollectionOwner"
$SPSiteCollectionSecondaryOwner = $Settings.FIAB.SharePoint2010.SiteCollectionSecondaryOwner -Replace "^.+\\" # we remove the domain part, just in case it there (shouldn't be though)
Write-Debug "SP Site Collection secondary owner: $SPSiteCollectionSecondaryOwner"

Export-ModuleMember -Function *
Export-ModuleMember -Alias *
Export-ModuleMember -Variable *