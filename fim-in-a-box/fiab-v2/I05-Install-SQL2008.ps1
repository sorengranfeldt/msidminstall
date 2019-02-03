# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# December 20, 2011 | Soren Granfeldt
#	- initial version
# December 23, 2011 | Soren Granfeldt
#	- added switch R2 for SQL Server 2008 R2 support (also added configuration file to kit)
# January 4, 2012 | Soren Granfeldt
#	- changed to use setting SoftwareRootPath to find location of software

param 
(
	[switch] $R2 = $false
)

.\Common-InitializeScript.ps1

if ([bool] $Settings.FIAB.SQLServer.UseLocalSQLServer)
{
	if ($R2) {$R2Text = "R2"} else {$R2Text = ""}
	Write-Host "Installing Prerequisites for SQL Server 2008 $R2Text"
	Import-Module ServerManager
	Add-WindowsFeature Application-Server
	
	$SoftwarePath = "$($Settings.FIAB.General.SoftwareRootPath)"
	$PathToSoftware = Join-Path $SoftwarePath "\SQL2008$($R2Text)"
	$SQLSettingsFile = "$PWD\ConfigurationFiles\SQL2008$($R2Text).Installation.Config.ini"

	$Cnt = Get-Content $SQLSettingsFile
	$Cnt = $Cnt -Replace "\[DOMAIN\]", $DomainNetBIOSName
	$Cnt = $Cnt -Replace "\[SQLServerAgent\]", $Settings.FIAB.General.ServiceAccounts.SQLServerAgent
	$Cnt = $Cnt -Replace "\[SQLServerAgentPassword\]", $Settings.FIAB.General.ServiceAccounts.SQLServerAgentPassword
	$Cnt = $Cnt -Replace "\[SQLServer\]", $Settings.FIAB.General.ServiceAccounts.SQLServer
	$Cnt = $Cnt -Replace "\[SQLServerPassword\]", $Settings.FIAB.General.ServiceAccounts.SQLServerPassword
	$Cnt = $Cnt -Replace "\[MEDIASOURCE\]", $PathToSoftware
	$Cnt = $Cnt -Replace "\[CURRENTUSERNAME\]", $ShortUsername
	Set-Content -Path "$SQLSettingsFile.install" -Value $Cnt

	Write-Host "Installing SQL Server 2008 $R2Text"
	Write-Host "Path to configuration file: $($SQLSettingsFile).install"
	$Setup = Join-Path "$PathToSoftware" "setup.exe"
	Write-Host "Setup path: $Setup"
	Start-Process -FilePath $Setup -ArgumentList /ConfigurationFile="$($SQLSettingsFile).install" -Wait
}
else
{
	Write-Host "Settings does not specify installing SQL Server 2008 $R2Text locally."
}

.\Common-TerminateScript.ps1