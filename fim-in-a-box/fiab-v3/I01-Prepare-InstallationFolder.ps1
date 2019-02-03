# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# January 9, 2012 | Soren Granfeldt
#	- initial version
# January 9, 2012 | Soren Granfeldt
#	- added extra error handling and loading of new FIAB module
#	- added progress bar

try
{
	Import-Module .\FIAB-Module.psm1 -Force

	$Dirs = "Logs", "Backup", "SW\FIMR2", "SW\SQL2008", "SW\SQL2008R2", "SW\SP2010", "ManagementAgents"

	$Total = $Dirs.Count
	$i = 0
	foreach ($Dir in $Dirs)
	{
		Write-Progress -id 1 -activity "Creating directory $Dir" -status "whatever" -percentComplete ($i*(100/$Total));
		$i++
		if (!(Test-Path $Dir))
		{
			Write-Debug "Creating directory $Dir"
			New-Item -Type Directory -Path $Dir | Out-Null

		}
		else
		{
			Write-Warning "Directory $Dir already exists"
		}
	}
}
catch
{
	Write-Error $_.Exception.Message
}
finally
{
	Write-Debug "Script exited"
}