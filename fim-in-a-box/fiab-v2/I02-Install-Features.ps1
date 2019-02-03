# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# December 15, 2011 | Soren Granfeldt
#	- initial version

function Install-Feature($feature)
{
	if ((Get-WindowsFeature $feature).Installed) 
	{
		"$feature is already installed"
	}	
	else
	{
		"Installing $feature"
		Add-WindowsFeature $feature -IncludeAllSubFeature
	}	
}

.\Common-InitializeScript.ps1

Write-Debug "Adding ServerManager Module"
Import-Module ServerManager

Install-Feature -feature NET-Framework
Install-Feature -feature RSAT-ADDS

.\Common-TerminateScript.ps1
