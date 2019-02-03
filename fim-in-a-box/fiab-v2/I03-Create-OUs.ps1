# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# December 16, 2011 | Soren Granfeldt
#	- initial version

.\Common-InitializeScript.ps1

function Create-OU($OU)
{
	if ([ADSI]::Exists("LDAP://$OU,$DefaultNamingContext"))
	{
		Write-Host "OU $OU already exists"
	}
	else
	{
		$objOU = $objDomain.Create("OrganizationalUnit",  $OU)
		$objOU.SetInfo()
	}
}

$objDomain = [ADSI] "LDAP://$DefaultNamingContext"

Create-OU -OU $Settings.FIAB.General.ManagedOU
Create-OU -OU $Settings.FIAB.General.ServiceAccountsOU

.\Common-TerminateScript.ps1
