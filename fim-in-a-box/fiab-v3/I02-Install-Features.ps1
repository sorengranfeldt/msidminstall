# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# December 15, 2011 | Soren Granfeldt
#	- initial version
# June 14, 2012 | Soren Granfeldt
#	- function moved to module

function Install-Feature($feature)
{
	if ((Get-WindowsFeature $feature).Installed) 
	{
		Write-Verbose "$feature is already installed"
	}	
	else
	{
		Write-Verbose "Installing $feature"
		Add-WindowsFeature $feature -IncludeAllSubFeature
	}	
}

$Activity = "Installing required features"

Write-Progress -Id 1 -Activity $Activity -status "Importing FIAB module"
Import-Module .\FIAB-Module.psm1 -Force

Write-Verbose "Adding ServerManager Module"
Import-Module ServerManager

"NET-Framework", "RSAT-ADDS" | foreach `
{
	$Feature = $_
	Write-Progress -Id 2 -Activity "Installing" -status $Feature
	Install-Feature -feature $Feature
}
