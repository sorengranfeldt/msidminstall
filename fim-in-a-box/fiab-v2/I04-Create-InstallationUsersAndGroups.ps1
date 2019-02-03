# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# December 10, 2010 | Soren Granfeldt
#	- initial script
# December 19, 2011 | Soren Granfeldt
#	- changed for automated installation
#	- added code to make current user a member of
#	  the FIMSyncAdmins group
# December 23, 2011 | Soren Granfeldt
#	- added support for setting "Password Never Expires" on creation
#	- added support for disabling "Must Change Password On Next Logon"
# January 9, 2011 | Soren Granfeldt
#	- fixed spelling error for password parameter for FIM Sync Account

.\Common-InitializeScript.ps1

function CreateUser($AccountName, $Password, $Description)
{
	Write-Host "  Creating user '$AccountName'"
	if ([ADSI]::Exists("LDAP://CN=$AccountName,$($Settings.FIAB.General.ServiceAccountsOU),$DefaultNamingContext"))
	{
		Write-Host "  User $AccountName already exists"
	}
	else
	{
		$UserOU = [ADSI] "LDAP://$($Settings.FIAB.General.ServiceAccountsOU),$DefaultNamingContext"
		$User = $UserOU.create("user","cn=$AccountName")
		$User.put("sAMAccountName", "$AccountName")
		$User.put("description", "$Description")
		$User.SetInfo()
		$userAccountControl = $User.userAccountControl.value -band (-bnot 2)
		$UserAccountControl = $UserAccountControl -bor 0x10000
		$User.put("userAccountControl", $UserAccountControl)
		$User.put("pwdLastSet", -1)
		$user.SetInfo() 
		$User.SetPassword($Password)
		$User.SetInfo()
	}
}

function CreateGroup($AccountName)
{
	Write-Host "  Creating group '$AccountName'"
	if ([ADSI]::Exists("LDAP://CN=$AccountName,$($Settings.FIAB.General.ServiceAccountsOU),$DefaultNamingContext"))
	{
		Write-Host "  Group $AccountName already exists"
	}
	else
	{
		$GroupOU = [ADSI] "LDAP://$($Settings.FIAB.General.ServiceAccountsOU),$DefaultNamingContext"
		$Group = $GroupOU.Create("group", "CN=" + $AccountName)
		$Group.Put("sAMAccountName", $AccountName )
		$Group.SetInfo()
	}
}

if ($Settings.FIAB.SQLServer.UseLocalSQLServer)
{
	Write-Host "Creating SQL Service Account users"
	CreateUser -AccountName $Settings.FIAB.General.ServiceAccounts.SQLServer      -Password $Settings.FIAB.General.ServiceAccounts.SQLServerPassword      -Description "SQL Server 2008 - Service Account" 
	CreateUser -AccountName $Settings.FIAB.General.ServiceAccounts.SQLServerAgent -Password	$Settings.FIAB.General.ServiceAccounts.SQLServerAgentPassword -Description "SQL Server 2008 Agent - Service Account" 
}

Write-Host "Creating Service Account users"
CreateUser -AccountName $Settings.FIAB.General.ServiceAccounts.SharePointConfigService -Password $Settings.FIAB.General.ServiceAccounts.SharePointConfigServicePassword -Description "SharePoint Database Access - Service Account"
CreateUser -AccountName $Settings.FIAB.General.ServiceAccounts.SharePointApplicationPoolService -Password $Settings.FIAB.General.ServiceAccounts.SharePointApplicationPoolServicePassword -Description "SharePoint Application Pool - Service Account"
CreateUser -AccountName $Settings.FIAB.General.ServiceAccounts.FIMSynchronizationService -Password $Settings.FIAB.General.ServiceAccounts.FIMSynchronizationServicePassword -Description "FIM Synchronization Service - Service Account" 
CreateUser -AccountName $Settings.FIAB.General.ServiceAccounts.FIMService -Password $Settings.FIAB.General.ServiceAccounts.FIMServicePassword -Description "FIM Service - Service Account" 
CreateUser -AccountName $Settings.FIAB.General.ServiceAccounts.ManagementAgentAD -Password $Settings.FIAB.General.ServiceAccounts.ManagementAgentADPassword -Description "Active Directory Management Agent - Service Account" 
CreateUser -AccountName $Settings.FIAB.General.ServiceAccounts.ManagementAgentFIM -Password $Settings.FIAB.General.ServiceAccounts.ManagementAgentFIMPassword -Description "FIM Management Agent Service Account" 

Write-Host "Creating Synchronization Service groups"
CreateGroup -AccountName "$($Settings.FIAB.SynchronizationService.GroupAdmins)"
CreateGroup -AccountName "$($Settings.FIAB.SynchronizationService.GroupBrowse)"
CreateGroup -AccountName "$($Settings.FIAB.SynchronizationService.GroupAccountJoiners)"
CreateGroup -AccountName "$($Settings.FIAB.SynchronizationService.GroupOperators)"
CreateGroup -AccountName "$($Settings.FIAB.SynchronizationService.GroupPasswordSet)"
Write-Host "Created Synchronization Service groups"

# Put SVC-FIM-Service ==> FIMSyncAdmins or FIMSyncPasswordSet
Write-Host "Enabling default group membership"
NET GROUP $Settings.FIAB.SynchronizationService.GroupAdmins $Settings.FIAB.General.ServiceAccounts.FIMService /ADD /DOMAIN
NET GROUP $Settings.FIAB.SynchronizationService.GroupPasswordSet $Settings.FIAB.General.ServiceAccounts.FIMService /ADD /DOMAIN

# Put the current user to the FIMSyncAdmins group
NET GROUP $Settings.FIAB.SynchronizationService.GroupAdmins ($Username  -Replace "^.+\\", "") /ADD /DOMAIN

Write-Host "`r`nApplying Local Security Settings"
Write-Host "For the FIM Synchronization Service service account to be able to impersonate the FIM MA account, `r`nthe FIM MA must be able to log on locally."
.\ntrights.exe +r SeInteractiveLogonRight -u "$DomainNetBIOSName\$($Settings.FIAB.General.ServiceAccounts.FIMService)"

.\Common-TerminateScript.ps1
