# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# January 9, 2012 | Soren Granfeldt
#	- initial version
# June 28, 2012 | Soren Granfeldt
#	- added write-progress

$Activity = "Enabling Kerberos on IIS"

Write-Progress -Id 1 -Activity $Activity -status "Importing FIAB module"
Import-Module .\FIAB-Module.psm1 -Force

$SystemRoot = (Join-Path $Env:SystemRoot "System32\inetsrv")
$BackupDir = (Join-Path $PWD "Backup")
$DateString = (Get-Date).ToString("yyyyMMddHHmmss")

Push-Location $SystemRoot

Write-Progress -Id 1 -Activity $Activity -status "Backing up applicationHost.config" -PercentComplete 0
Copy (Join-Path $SystemRoot "config\applicationHost.config") (Join-Path $BackupDir "IIS.applicationHost.config.$($DateString).bak") -Force

Write-Progress -Id 1 -Activity $Activity -status "Enabling Kerberos on IIS" -PercentComplete 33
.\appcmd.exe set config $SPWebApplicationName /Section:WindowsAuthentication /UseKernelMode:false /UseAppPoolCredentials:true /Commit:MACHINE/WEBROOT/APPHOST

Write-Progress -Id 1 -Activity $Activity -status "Saving copy of reconfigured file to backup directory" -PercentComplete 0
Copy-Item (Join-Path $SystemRoot "config\applicationHost.config") (Join-Path $BackupDir "IIS.applicationHost.config.new")
Pop-Location

Write-Progress -Id 1 -Activity $Activity -status "Resetting IIS" -PercentComplete 66
IISRESET -NoForce
