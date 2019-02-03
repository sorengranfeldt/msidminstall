# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# December 16, 2011 | Soren Granfeldt
#	- initial version
# February 23, 2012 | Soren Granfeldt
#	- fixed detection of NetBIOS domain name to work with multi-domain forests

Write-Host "Microsoft FIM-in-a-Box | System Center for People"
Write-Host "(c) Copyright 2010-2012 Microsoft Corporation. All rights reserved.`r`n"

[XML] $global:Settings = Get-Content FIM-in-a-Box.Settings.xml

$global:CurrentDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()

$global:RootDse = [ADSI] "LDAP://RootDSE"
$global:DefaultNamingContext = $RootDse.defaultNamingContext
$global:ConfigurationNamingContext = $RootDse.configurationNamingContext


$global:Searcher = New-Object System.DirectoryServices.DirectorySearcher([ADSI] "LDAP://$ConfigurationNamingContext")
$Searcher.Filter = "(&(objectCategory=crossRef)(nCName=$DefaultNamingContext))"
$Searcher.PropertiesToLoad.Add("nETBIOSName")
$global:Results = $Searcher.FindOne()

if ($Results)
{
	$global:DomainNetBIOSName = $Results.Properties.Item("nETBIOSName")
}

$global:Domain = [ADSI] "LDAP://$DefaultNamingContext"
$global:FQDN = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
$global:Username = (whoami).ToUpper()
$global:ShortUsername = (whoami).ToUpper() -Replace "^.+\\", ""
$global:Hostname = (hostname).ToUpper()
$global:DnsHostname = [System.Net.Dns]::GetHostEntry($hostname).HostName
