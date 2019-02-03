# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# January 12, 2012 | Soren Granfeldt
#	- initial version

.\Common-InitializeScript.ps1

Import-Module (Join-Path $PWD "FIM-Modules.psm1") -Force
If(@(Get-PSSnapin | Where-Object {$_.Name -eq "FIMAutomation"} ).count -eq 0) {Add-PSSnapin FIMAutomation}

$MPRs = @("General: Users can read schema related resources", "General: Users can read non-administrative configuration resources", "User management: Users can read attributes of their own")
foreach ($MPR in $MPRs) { Enable-MPR -MPRName $MPR }

.\Common-TerminateScript.ps1
