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
# June 29, 2012 | Soren Granfeldt
#	- adjusted to support R2
#	- added parameter ShowGuidedUI to allow for guided/controlled installation
# July 5, 2012 | Soren Granfeldt
#	- added statement to automatically export encryption key to backup folder

PARAM
(
	[switch] $ShowGuidedUI
)

$Activity = "FIM Synchronization Server"

Write-Progress -Id 1 -Activity $Activity -status "Importing FIAB module"
Import-Module .\FIAB-Module.psm1 -Force

$MsiFile = Join-Path $SoftwarePath "FIMR2\Synchronization Service\Synchronization Service.msi"
$LogFile = "$PWD\Logs\FIMSync.Installation-{0:yyyyMMdd-HHmmss}.log" -F (Get-Date)

if ($SQLServerInstance) { $SQLInstance = "SQLINSTANCE=$SQLServerWithInstance" }
if ($ShowGuidedUI) { $QuietParam = "" } else { $QuietParam = "/qn" }

$Arguments = "/LV $LogFile $QuietParam /i ""$MsiFile"" STORESERVER=$SQLServer $SQLInstance SERVICEACCOUNT=$SyncServiceAccount SERVICEPASSWORD=$SyncServiceAccountPassword SERVICEDOMAIN=$DomainNetBIOSName Reboot=ReallySuppress GROUPADMINS=$SyncGroupAdmins GROUPOPERATORS=$SyncGroupOperators GROUPACCOUNTJOINERS=$SyncGroupAccountJoiners GROUPBROWSE=$SyncGroupBrowse GROUPPASSWORDSET=$SyncGroupPasswordSet FIREWALL_CONF=1 ACCEPT_EULA=1"
Write-Debug "Installation Command-line: $Arguments"

Write-Progress -Id 1 -Activity $Activity -status "Installing"
Start-Process -FilePath MSIEXEC.EXE -ArgumentList $Arguments -Wait

# There is not a parameter you can pass in for saving the backup key siliently during install.
# You can pass /quiet & it will skip saving the backup key during install. Then you could later 
# export the backup key using the MIISKMU.exe tool using a command like the following.
# "%ProgramFiles%\Microsoft Forefront Identity Manager\2010\Synchronization Service\Bin\miiskmu.exe" /e c:\Temp\MyKey.bin /u:<MyDomain>\<MyAlias> <MyPassword> /q
# Documentation about miiskmu tool: http://technet.microsoft.com/en-us/library/cc787957(WS.10).aspx
Write-Progress -Id 1 -Activity $Activity -status "Exporting encryption key to Backup"
Start-Process -FilePath "C:\Program Files\Microsoft Forefront Identity Manager\2010\Synchronization Service\bin\miiskmu.exe" -ArgumentList "/e Backup\FIMEncryptionKey.bin /u:$DomainNetBIOSName\$SyncServiceAccount $SyncServiceAccountPassword /q" -Wait


