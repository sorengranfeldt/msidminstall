# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# December 16, 2011 | Soren Granfeldt
#	- initial version
# December 20, 2011 | Soren Granfeldt
#	- adjusted for new settings file format
# December 28, 2011 | Soren Granfeldt
#	- removed SHORTFILENAMES=TRUE, since this does not work with this .MSI
# January 3, 2012 | Soren Granfeldt
#	- added support for use of remote SQL server and SQL instance
#	- added additional progress information
#	- changed to use setting SoftwareRootPath to find location of software
.\Common-InitializeScript.ps1

$SoftwarePath = "$($Settings.FIAB.General.SoftwareRootPath)"
$MsiFile = Join-Path $SoftwarePath "FIM\Synchronization Service\Synchronization Service.msi"
$LogFile = "$PWD\Logs\FIMSync.Installation.log"

if (Test-Path $LogFile) {Remove-Item $LogFile}

if ($Settings.FIAB.SQLServer.SQLServer) { $StoreServer = "STORESERVER=$($Settings.FIAB.SQLServer.SQLServer)" }
if ($Settings.FIAB.SQLServer.SQLServerInstance) { $SQLInstance = "SQLINSTANCE=$($Settings.FIAB.SQLServer.SQLServerInstance)" }

$Arguments = "/LV $LogFile /qn /i ""$MsiFile"" $StoreServer $SQLInstance ACCEPT_EULA=1 SERVICEACCOUNT=$($Settings.FIAB.General.ServiceAccounts.FIMSynchronizationService) SERVICEPASSWORD=$($Settings.FIAB.General.ServiceAccounts.FIMSynchronizationServicePassword) SERVICEDOMAIN=$($DomainNetBIOSName) Reboot=ReallySuppress GROUPADMINS=$DomainNetBIOSName\$($Settings.FIAB.SynchronizationService.GroupAdmins) GROUPOPERATORS=$DomainNetBIOSName\$($Settings.FIAB.SynchronizationService.GroupOperators) GROUPACCOUNTJOINERS=$DomainNetBIOSName\$($Settings.FIAB.SynchronizationService.GroupAccountJoiners) GROUPBROWSE=$DomainNetBIOSName\$($Settings.FIAB.SynchronizationService.GroupBrowse) GROUPPASSWORDSET=$DomainNetBIOSName\$($Settings.FIAB.SynchronizationService.GroupPasswordSet) FIREWALL_CONF=1"

Write-Host "Installing FIM Synchronization Server using this command-line`r`n"
Write-Host "Command-line: $Arguments"

Start-Process -FilePath MSIEXEC.EXE -ArgumentList $Arguments -Wait

# There is not a parameter you can pass in for saving the backup key siliently during install.
# You can pass /quiet & it will skip saving the backup key during install. Then you could later 
# export the backup key using the MIISKMU.exe tool using a command like the following.
# "%ProgramFiles%\Microsoft Forefront Identity Manager\2010\Synchronization Service\Bin\miiskmu.exe" /e c:\Temp\MyKey.bin /u:<MyDomain>\<MyAlias> <MyPassword> /q
# Documentation about miiskmu tool: http://technet.microsoft.com/en-us/library/cc787957(WS.10).aspx

Write-Host "`r`nInstallation complete (please export backup key manually)"
.\Common-TerminateScript.ps1