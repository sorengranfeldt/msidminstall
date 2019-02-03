# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# January 12, 2012 | Soren Granfeldt
#	- initial version based on http://blog.goverco.com/2011/08/granting-replicating-directory.html

.\Common-InitializeScript.ps1

# translate to SID
$UserPrincipal = New-Object Security.Principal.NTAccount("$DomainNetBIOSName", "$($Settings.FIAB.General.ServiceAccounts.ManagementAgentAD)")
$SID = $UserPrincipal.Translate([System.Security.Principal.SecurityIdentifier]).Value
DSACLS "$DefaultNamingContext" /G "$($SID):CA;Replicating Directory Changes";

.\Common-TerminateScript.ps1
