# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# December 20, 2011 | Soren Granfeldt
#	- initial version
# December 23, 2011 | Soren Granfeldt
#	- added switch R2 for SQL Server 2008 R2 support (also added configuration file to kit)
# January 4, 2012 | Soren Granfeldt
#	- changed to use setting SoftwareRootPath to find location of software
# June 28, 2012 | Soren Granfeldt
#	- revised to support FIM 2010 R2

param 
(
	[switch] $R2 = $false
)

if ($R2) {$R2Text = "R2"} else {$R2Text = ""}
$Activity = ("Installing SQL 2008 $R2Text").Trim()

Write-Progress -Id 1 -Activity $Activity -status "Importing FIAB module"
Import-Module .\FIAB-Module.psm1 -Force

if ($UseLocalSqlServer)
{
	Write-Progress -Id 2 -ParentId 1 -Activity $Activity -status "Installing Prerequisites"
	Import-Module ServerManager
	Add-WindowsFeature Application-Server
	
	$PathToSoftware = Join-Path $SoftwarePath "\SQL2008$($R2Text)"
	$SQLSettingsFile = "$PWD\ConfigurationFiles\SQL2008$($R2Text).Installation.Config.ini"

	Write-Progress -Id 2 -ParentId 1 -Activity $Activity -status "Preparing installation file"
	$Cnt = Get-Content $SQLSettingsFile
	$Cnt = $Cnt -Replace "\[DOMAIN\]", $DomainNetBIOSName
	$Cnt = $Cnt -Replace "\[SQLServerAgent\]", $SQLServerServiceAccount
	$Cnt = $Cnt -Replace "\[SQLServerAgentPassword\]", $SQLServerAgentServiceAccountPassword
	$Cnt = $Cnt -Replace "\[SQLServer\]", $SQLServerServiceAccount
	$Cnt = $Cnt -Replace "\[SQLServerPassword\]", $SQLServerServiceAccountPassword
	$Cnt = $Cnt -Replace "\[MEDIASOURCE\]", $PathToSoftware
	$Cnt = $Cnt -Replace "\[CURRENTUSERNAME\]", $UsernameWithoutDomain
	Set-Content -Path "$($SQLSettingsFile).install" -Value $Cnt

	Write-Debug "Path to configuration file: $($SQLSettingsFile).install"
	Write-Progress -Id 2 -ParentId 1 -Activity $Activity -status "Installing"
	Start-Process -FilePath (Join-Path "$PathToSoftware" "setup.exe") -ArgumentList /ConfigurationFile="$($SQLSettingsFile).install" -Wait
}
else
{
	Write-Warning "Settings does not specify installing SQL Server 2008 $R2Text locally."
}
