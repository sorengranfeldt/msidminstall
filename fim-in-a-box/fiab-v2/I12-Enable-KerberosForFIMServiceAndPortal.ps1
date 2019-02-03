# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# January 9, 2012 | Soren Granfeldt
#	- initial version

.\Common-InitializeScript.ps1

Import-Module WebAdministration

$DateString = (Get-Date).ToString("yyyyMMddHHmmss")

$SPWebpath = (Get-Item 'IIS:\Sites\SharePoint - 80').PhysicalPath
Copy (Join-Path $SPWebpath "web.config") (Join-Path $PWD "Backup\web.config.$($DateString).bak") -Force
[XML] $WebConfigFile = Get-Content (Join-Path $SPWebPath "web.config")
$WebConfigFile.configuration.resourceManagementClient.SetAttribute("requireKerberos", "true")
$WebConfigFile.Save((Join-Path $SPWebPath "web.config"))

Write-Host "Resetting Internet Information Services (IIS)"
IISRESET -NoForce

.\Common-TerminateScript.ps1