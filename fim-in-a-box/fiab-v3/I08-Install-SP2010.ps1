# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# June 28, 2012 | Soren Granfeldt
#	- initial version

Import-Module .\FIAB-Module.psm1 -Force

VERIFY POWERSHELL v2 as installation will fail on 3.0 or higher
http://danieladeniji.wordpress.com/2013/10/11/technical-powershell-microsoft-net-clr-version/

$Activity = "Installing SharePoint 2010 Foundation"

# Installing Prerequisites
# Optionally, we can download all requirements and
# follow this http://joelblogs.co.uk/2011/03/14/unattended-install-of-sharepoint-2010-prerequisites-optionally-without-an-internet-connection/
Write-Progress -Id 1 -Activity $Activity -Status "Installing prerequisites" -PercentComplete 0
Start-Process -FilePath (Join-Path $SoftwarePath "SP2010\PrerequisiteInstaller.exe") -ArgumentList "/Unattended" -Wait

$InstallationTemplateFile = Join-Path $PWD "\ConfigurationFiles\SharePoint2010Foundation.Installation.Template.xml"
Write-Debug $InstallationTemplateFile
$InstallationFile = Join-Path $PWD "\ConfigurationFiles\SharePoint2010Foundation.Installation.config.xml"
Write-Debug $InstallationFile

Write-Progress -Id 1 -Activity $Activity -Status "Configuring setup file" -PercentComplete 10
Copy $InstallationTemplateFile ($InstallationFile) -Force
[XML] $F = Get-Content $InstallationFile
$F.Configuration.Logging.SetAttribute("Path", (Join-Path $PWD "Logs"))
$F.Save( $InstallationFile )

Write-Progress -Id 1 -Activity $Activity -Status "Installing SharePoint Services" -PercentComplete 30
Start-Process -FilePath (Join-Path $SoftwarePath "SP2010\Setup.exe") -ArgumentList "/Config $InstallationFile" -Wait
