# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# January 9, 2012 | Soren Granfeldt
#	- initial version

.\Common-InitializeScript.ps1

$Dirs = "Logs", "Backup", "SW\FIM", "SW\SQL2008", "SW\SQL2008R2", "SW\WSS3SP2x64", "SW\_Patches\FIM", "SW\_Patches\SQL", "SW\_Patches\WSS", "ManagementAgents"

foreach ($Dir in $Dirs)
{ 
	New-Item -Type Directory -Path $Dir -ErrorAction SilentlyContinue | Out-Null
}

.\Common-TerminateScript.ps1