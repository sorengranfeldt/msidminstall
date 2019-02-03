# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# December 16, 2011 | Soren Granfeldt
#	- initial version
# June 29, 2012 | Soren Granfeldt
#	- adjusted for R2

$Activity = "Creating Organizational Units (OU's)"

Write-Progress -Id 1 -Activity $Activity -status "Importing FIAB module"
Import-Module .\FIAB-Module.psm1 -Force

function Create-OU($OU)
{
	if ([ADSI]::Exists("LDAP://$OU,$DefaultNamingContext"))
	{
		Write-Warning "OU '$OU' already exists"
	}
	else
	{
		$objOU = $objDomain.Create("OrganizationalUnit",  $OU)
		$objOU.SetInfo()
	}
}

$objDomain = [ADSI] "LDAP://$DefaultNamingContext"

"$ManagedOU", "$ServiceAccountsOU" | foreach `
{
	Write-Progress -Id 2 -ParentId 1 -Activity $Activity -status "Creating $_"
	Create-OU -OU $_
}
