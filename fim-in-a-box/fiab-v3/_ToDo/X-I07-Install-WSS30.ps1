# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# December 15, 2011 | Soren Granfeldt
#	- initial version
# January 4, 2012 | Soren Granfeldt
#	- changed to use setting SoftwareRootPath to find location of software
# January 11, 2012 | Soren Granfeldt
#	- added automation of change of log path

.\Common-InitializeScript.ps1

$SoftwarePath = Join-Path "$($Settings.FIAB.General.SoftwareRootPath)" "\WSS3SP2x64\Setup.exe"
$InstallationFile = Join-Path "$PWD" "\ConfigurationFiles\SharePointServices.Installation.Config.xml.install"

Write-Host "Configuring setup file"
Copy (Join-Path "$PWD" "\ConfigurationFiles\SharePointServices.Installation.Config.xml") ($InstallationFile) -Force
[XML] $F = Get-Content $InstallationFile
$F.Configuration.Logging.SetAttribute("Path", (Join-Path "$PWD" "Logs"))
$F.Save( $InstallationFile )

Write-Host "Installing SharePoint Services - please wait..."
Start-Process -FilePath $SoftwarePath -ArgumentList "/config $InstallationFile" -Wait
Write-Host "Installed"

.\Common-TerminateScript.ps1