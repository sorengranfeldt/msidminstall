# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# December 10, 2010 | Soren Granfeldt
#	- initial script
# December 19, 2011 | Soren Granfeldt
#	- changed for automated installation
#	- added code to make current user a member of the FIMSyncAdmins group
# December 23, 2011 | Soren Granfeldt
#	- added support for setting "Password Never Expires" on creation
#	- added support for disabling "Must Change Password On Next Logon"
# January 9, 2011 | Soren Granfeldt
#	- fixed spelling error for password parameter for FIM Sync Account
# June 29, 2012 | Soren Granfeldt
#	- adjusted for R2

$Activity = "Creating users and groups"

Write-Progress -Id 1 -Activity $Activity -status "Importing FIAB module"
Import-Module .\FIAB-Module.psm1 -Force

Write-Progress -Id 1 -Activity $Activity -status "Importing Active Directory module"
Import-Module ActiveDirectory


function CreateUser($AccountName, $Password, $Description)
{
	Write-Debug "Creating user '$Accountname'"
	Write-Progress -Id 2 -ParentId 1 -Activity "Creating user" -status "$AccountName"
	$Account = ([ADSISearcher] "(&(objectClass=user)(sAMAccountName=$AccountName))").FindOne()
	if ($Account)
	{
		Write-Warning "User '$AccountName' already exists as $($Account.Path)"
	}
	else
	{
		$UserOU = [ADSI] "LDAP://$ServiceAccountsOU,$DefaultNamingContext"
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
	Write-Debug "Creating group '$Accountname'"
	Write-Progress -Id 2 -ParentId 1 -Activity "Creating group" -status "$AccountName"
	$Account = ([ADSISearcher] "(&(objectClass=group)(sAMAccountName=$AccountName))").FindOne()
	if ($Account)
	{
		Write-Warning "Group '$AccountName' already exists exists as $($Account.Path)"
	}
	else
	{
		$GroupOU = [ADSI] "LDAP://$ServiceAccountsOU,$DefaultNamingContext"
		$Group = $GroupOU.Create("group", "CN=" + $AccountName)
		$Group.Put("sAMAccountName", $AccountName )
		$Group.SetInfo()
	}
}

# create users
( 
	@{AccountType="FIMSA"; AccountName = $SyncServiceAccount; 			Password = $SyncServiceAccountPassword; 			Description = 'FIM Synchronization Service - Service Account' },
	@{AccountType="FIMSA"; AccountName = $FIMServiceServiceAccount; 	Password = $FIMServiceServiceAccountPassword;		Description = 'FIM Service - Service Account' },
	@{AccountType="FIMSA"; AccountName = $FIMPasswordResetServiceServiceAccount; 	Password = $FIMPasswordResetServiceServiceAccountPassword;		Description = 'FIM Password Reset Service - Service Account' },
	
	@{AccountType="SPSA"; AccountName = $SPConfigServiceServiceAccount; Password = $SPConfigServiceServiceAccountPassword; 	Description = 'SharePoint Database Access - Service Account' },
	@{AccountType="SPSA"; AccountName = $SPAppPoolServiceAccount;		Password = $SPAppPoolServiceAccountPassword; 		Description = 'SharePoint Application Pool - Service Account' },
	
	@{AccountType="MASA"; AccountName = $MAADServiceAccount; 			Password = $MAADServiceAccountPassword; 			Description = 'Active Directory Management Agent - Service Account' },
	@{AccountType="MASA"; AccountName = $MAFIMServiceAccount; 			Password = $MAFIMServiceAccountPassword; 			Description = 'FIM Management Agent - Service Account' },
	
	@{AccountType="SQLSA"; AccountName = $SQLServerServiceAccount; 		Password = $SQLServerServiceAccountPassword; 		Description = 'SQL Server 2008 - Service Account' },
	@{AccountType="SQLSA"; AccountName = $SQLServerAgentServiceAccount;	Password = $SQLServerAgentServiceAccountPassword; 	Description = 'SQL Server 2008 Agent - Service Account' }
) | foreach `
{
	if ( ($_.AccountType -eq "SQLMA" -and $UseLocalSqlServer) -or ($_.AccountType -ne "SQLMA") )
	{
		CreateUser -AccountName ($_.AccountName -replace '^.+\\') -Password $_.Password -Description $_.Description
	}
}

# create groups
(
	@{ AccountName=$SyncGroupAdmins},
	@{ AccountName=$SyncGroupOperators},
	@{ AccountName=$SyncGroupAccountJoiners},
	@{ AccountName=$SyncGroupBrowse},
	@{ AccountName=$SyncGroupPasswordSet}
) | foreach `
{
	CreateGroup -AccountName ($_.AccountName -replace '^.+\\')
}

function Add-GroupMember($Group, $NewMember)
{
	$Group = $Group -replace '^.+\\' # replace any leading domain names
	if (-not (Get-ADGroupMember $Group | ? {$_.SamAccountName -eq $NewMember}))
	{
		Add-AdGroupMember -Identity $Group $NewMember
	}
	else
	{
		Write-Warning "$NewMember is already a member of $Group"
	}
}

# Put SVC-FIM-Service ==> FIMSyncAdmins or FIMSyncPasswordSet
Write-Debug "Enabling default group membership"
Write-Progress -Id 2 -ParentId 1 -Activity "Adding group members" -status $SyncGroupAdmins
Add-GroupMember -Group $SyncGroupAdmins -NewMember $UsernameWithoutDomain
Add-GroupMember -Group $SyncGroupAdmins -NewMember $FIMServiceServiceAccount

Write-Progress -Id 2 -ParentId 1 -Activity "Adding group members" -status $SyncGroupPasswordSet
Add-GroupMember -Group $SyncGroupPasswordSet -NewMember $FIMServiceServiceAccount

Write-Progress -Id 2 -ParentId 1 -Activity "Adding group members" -status $SyncGroupBrowse
Add-GroupMember -Group $SyncGroupBrowse -NewMember $FIMServiceServiceAccount

# for the FIM Synchronization Service service account to be able to impersonate the FIM MA account, `r`nthe FIM MA must be able to log on locally.
Write-Progress -Id 2 -ParentId 1 -Activity "Applying Local Security Settings" -status $SyncGroupAdmins
.\ntrights.exe +r SeInteractiveLogonRight -u ('{0}\{1}' -F $DomainNetBIOSName, $MAFIMServiceAccount)
