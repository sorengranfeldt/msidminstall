# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# January 9, 2012 | Soren Granfeldt
#	- initial version
# June 29, 2012 | Soren Granfeldt
#	- adjusted for R2

$Activity = "Enable Kerberos for FIM Service and FIM Portal"

Write-Progress -Id 1 -Activity $Activity -status "Importing FIAB module"
Import-Module .\FIAB-Module.psm1 -Force
Write-Progress -Id 1 -Activity $Activity -status "Importing Web Administration module"
Import-Module WebAdministration

$DateString = (Get-Date).ToString("yyyyMMddHHmmss")

$SPWebpath = (Get-Item "IIS:\Sites\$SPWebApplicationName").PhysicalPath
Copy (Join-Path $SPWebpath "web.config") (Join-Path $PWD "Backup\web.config.$($DateString).bak") -Force
[XML] $WebConfigFile = Get-Content (Join-Path $SPWebPath "web.config")
$WebConfigFile.configuration.resourceManagementClient.SetAttribute("requireKerberos", "true")
$WebConfigFile.Save((Join-Path $SPWebPath "web.config"))

Write-Progress -Id 1 -Activity $Activity -status "Resetting IIS"
IISRESET -NoForce
