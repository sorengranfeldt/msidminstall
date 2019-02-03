# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# January 9, 2012 | Soren Granfeldt
#	- initial version

.\Common-InitializeScript.ps1

$SystemRoot = (Join-Path $Env:SystemRoot "System32\inetsrv")
$BackupDir = (Join-Path $PWD "Backup")
$DateString = (Get-Date).ToString("yyyyMMddHHmmss")

Push-Location $SystemRoot
Copy (Join-Path $SystemRoot "config\applicationHost.config") (Join-Path $BackupDir "IIS.applicationHost.config.$($DateString).bak") -Force
.\appcmd.exe set config "SharePoint - 80" /Section:WindowsAuthentication /UseKernelMode:false /UseAppPoolCredentials:true /Commit:MACHINE/WEBROOT/APPHOST
Copy-Item (Join-Path $SystemRoot "config\applicationHost.config") (Join-Path $BackupDir "IIS.applicationHost.config.new")
Pop-Location

Write-Host "Resetting Internet Information Services (IIS)"
IISRESET -NoForce

.\Common-TerminateScript.ps1
