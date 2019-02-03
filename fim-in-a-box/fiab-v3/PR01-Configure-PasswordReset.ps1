# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# January 12, 2011 | Soren Granfeldt
#	- initial script
# 	  WMI and DCOM permissions based on script from http://social.technet.microsoft.com/Forums/en-US/ilm2/thread/b85ccedc-68d8-4a8e-a4b3-f6ed952383a9
#	- issues have been seen where the default DCOM registry keys are missing from registry and then step 5 (DCMO) may fail due to NULL value.
#	  If this happens, you may need to go into the guide and follow the steps or go to Component Service (in Administrative Tools) and reapply 
#	  existing permissions to have the correct registry keys created in HKLM\SOFTWARE\Microsoft\ole
# January 12, 2011 | Soren Granfeldt
#	- minor modifications to match new settings configuration for service accounts

param (
	[switch] $All = $false,
	[switch] $Step1 = $false,
	[switch] $Step2 = $false,
	[switch] $Step3 = $false,
	[switch] $Step4 = $false,
	[switch] $Step5 = $false,
	[switch] $Step6 = $false,
	[switch] $Step7 = $false,
	[switch] $Step8 = $false
)

Write-Progress -Id 1 -Activity $Activity -status "Importing FIAB module"
Import-Module .\FIAB-Module.psm1 -Force

function Get-Sid
{
	PARAM ($DSIdentity)
	$ID = New-Object System.Security.Principal.NTAccount($DSIdentity)
	return $ID.Translate( [System.Security.Principal.SecurityIdentifier] ).ToString()
}

if ($Step1 -or $All)
{
	# Put SVC-FIM-Service ==> FIMSyncAdmins or FIMSyncPasswordSet
	Write-Host "STEP 1: Make the FIM 2010 Service account a member of the FIMSyncBrowse and FIMSyncPasswordSet groups. To make the FIM 2010 Service account a member of the FIMSyncBrowse and FIMSyncPasswordSet groups"
	NET GROUP $SyncGroupAdmins      $FIMServiceServiceAccount /ADD /DOMAIN
	NET GROUP $SyncGroupPasswordSet $FIMServiceServiceAccount /ADD /DOMAIN
	NET GROUP $SyncGroupBrowse      $FIMServiceServiceAccount /ADD /DOMAIN

	Write-Host "Restarting FIM services"
	Restart-Service -Verbose FIMSynchronizationService
	Restart-Service -Verbose FIMService
}

if ($Step2 -or $All)
{
	Write-Host "STEP 2: Enable password management on the management agent for AD DS on the FIM Synchronization Server"
	Write-Host "You must enable password management on the management agent for Active Directory Domain Services (AD DS). This makes it possible for AD DS to process the password reset requests that it receives."
	Write-Host "THIS IS A MANUAL STEP: Follow guide"
}

if ($Step3 -or $All)
{
	Write-Host "STEP 3: Enable FIM 2010 service account privileges in Windows Management Instrumentation on the FIM Synchronization Server"
	$sid = Get-Sid $FIMServiceServiceAccount
	
	#WMI Permission - Enable Account, Remote Enable for This namespace and subnamespaces 
	$WMISDDL = "A;CI;CCWP;;;$sid" 

	#PartialMatch
	$WMISDDLPartialMatch = "A;\w*;\w+;;;$sid"
	
	Write-Host "`nWorking on $Hostname..."
	$security = Get-WmiObject -ComputerName $Hostname -Namespace root/cimv2 -Class __SystemSecurity
	$binarySD = @($null)
	$result = $security.PsBase.InvokeMethod("GetSD", $binarySD)

	# Convert the current permissions to SDDL 
	Write-Host "`tConverting current permissions to SDDL format..."
	$converter = New-Object System.Management.ManagementClass Win32_SecurityDescriptorHelper
	$CurrentWMISDDL = $converter.BinarySDToSDDL($binarySD[0])
	$CurrentWMISDDL

	# Build the new permissions 
	Write-Host "`tBuilding the new permissions..."
	if (($CurrentWMISDDL.SDDL -match $WMISDDLPartialMatch) -and ($CurrentWMISDDL.SDDL -notmatch $WMISDDL))
	{
		$NewWMISDDL = $CurrentWMISDDL.SDDL -replace $WMISDDLPartialMatch, $WMISDDL
	}
	else
	{
		$NewWMISDDL = $CurrentWMISDDL.SDDL + "(" + $WMISDDL + ")"
	}

	# Convert SDDL back to Binary 
	Write-Host `t"Converting SDDL back into binary form..."
	$WMIbinarySD = $converter.SDDLToBinarySD($NewWMISDDL)
	$WMIconvertedPermissions = ,$WMIbinarySD.BinarySD
 
	# Apply the changes
	Write-Host "`tApplying changes..."
	if ($CurrentWMISDDL.SDDL -match $WMISDDL)
	{
		Write-Host "`t`tCurrent WMI Permissions matches desired value."
	}
	else
	{
		$result = $security.PsBase.InvokeMethod("SetSD", $WMIconvertedPermissions) 
		if($result='0'){Write-Host "`t`tApplied WMI Security complete."}
	}
}

if ($Step4 -or $All)
{
	Write-Host "STEP 4: Allow Windows Management Instrumentation traffic through the Windows Firewall on the FIM Synchronization Server"
	netsh advfirewall firewall set rule group="Windows Management Instrumentation (WMI)" new enable=yes

	# If you want to control the firewall rules more granularly, you could use the rules below
	#netsh advfirewall firewall set rule name="Windows Management Instrumentation (ASync-In)"  new enable=no  profile=any
	#netsh advfirewall firewall set rule name="Windows Management Instrumentation (ASync-In)"  new enable=no  profile=private
	#netsh advfirewall firewall set rule name="Windows Management Instrumentation (ASync-In)"  new enable=no  profile=public
	#netsh advfirewall firewall set rule name="Windows Management Instrumentation (ASync-In)"  new enable=yes  profile=domain

	#netsh advfirewall firewall set rule name="Windows Management Instrumentation (DCOM-In)"  new enable=no  profile=any
	#netsh advfirewall firewall set rule name="Windows Management Instrumentation (DCOM-In)"  new enable=no  profile=private
	#netsh advfirewall firewall set rule name="Windows Management Instrumentation (DCOM-In)"  new enable=no  profile=public
	#netsh advfirewall firewall set rule name="Windows Management Instrumentation (DCOM-In)"  new enable=yes  profile=domain

	#netsh advfirewall firewall set rule name="Windows Management Instrumentation (WMI-In)"  new enable=no  profile=any
	#netsh advfirewall firewall set rule name="Windows Management Instrumentation (WMI-In)"  new enable=no  profile=private
	#netsh advfirewall firewall set rule name="Windows Management Instrumentation (WMI-In)"  new enable=no  profile=public
	#netsh advfirewall firewall set rule name="Windows Management Instrumentation (WMI-In)"  new enable=yes  profile=domain

	#netsh advfirewall firewall set rule name="Windows Management Instrumentation (WMI-Out)"  new enable=no  profile=any
	#netsh advfirewall firewall set rule name="Windows Management Instrumentation (WMI-Out)"  new enable=no  profile=private
	#netsh advfirewall firewall set rule name="Windows Management Instrumentation (WMI-Out)"  new enable=no  profile=public
	#netsh advfirewall firewall set rule name="Windows Management Instrumentation (WMI-Out)"  new enable=yes  profile=domain
}

if ($Step5 -or $All)
{
	Write-Host "STEP 5: Enable DCOM for the FIM service account"
	$sid = Get-Sid $FIMServiceServiceAccount

	#MachineLaunchRestriction - Local Launch, Remote Launch, Local Activation, Remote Activation
	$DCOMSDDLMachineLaunchRestriction = "A;;CCDCLCSWRP;;;$sid"

	#MachineAccessRestriction - Local Access, Remote Access
	$DCOMSDDLMachineAccessRestriction = "A;;CCDCLC;;;$sid"

	#DefaultLaunchPermission - Local Launch, Remote Launch, Local Activation, Remote Activation
	$DCOMSDDLDefaultLaunchPermission = "A;;CCDCLCSWRP;;;$sid"

	#DefaultAccessPermision - Local Access, Remote Access
	$DCOMSDDLDefaultAccessPermision = "A;;CCDCLC;;;$sid"

	#PartialMatch
	$DCOMSDDLPartialMatch = "A;;\w+;;;$sid"
	
	Write-Host "Working on $Hostname with principal '$($Settings.FIAB.General.ServiceAccounts.FIMService)' ($sid)"
	# Get the respective binary values of the DCOM registry entries
	$Reg = [WMIClass]"\\$Hostname\root\default:StdRegProv"
	$DCOMMachineLaunchRestriction = $Reg.GetBinaryValue(2147483650,"software\microsoft\ole","MachineLaunchRestriction").uValue
	$DCOMMachineAccessRestriction = $Reg.GetBinaryValue(2147483650,"software\microsoft\ole","MachineAccessRestriction").uValue
	$DCOMDefaultLaunchPermission = $Reg.GetBinaryValue(2147483650,"software\microsoft\ole","DefaultLaunchPermission").uValue
	$DCOMDefaultAccessPermission = $Reg.GetBinaryValue(2147483650,"software\microsoft\ole","DefaultAccessPermission").uValue

	# Convert the current permissions to SDDL
	Write-Host "`tConverting current permissions to SDDL format..."
	$converter = New-Object System.Management.ManagementClass Win32_SecurityDescriptorHelper
	$CurrentDCOMSDDLMachineLaunchRestriction = $converter.BinarySDToSDDL($DCOMMachineLaunchRestriction)
	$CurrentDCOMSDDLMachineAccessRestriction = $converter.BinarySDToSDDL($DCOMMachineAccessRestriction)
	$CurrentDCOMSDDLDefaultLaunchPermission = $converter.BinarySDToSDDL($DCOMDefaultLaunchPermission)
	$CurrentDCOMSDDLDefaultAccessPermission = $converter.BinarySDToSDDL($DCOMDefaultAccessPermission)

	# Build the new permissions
	Write-Host "`tBuilding the new permissions..."
	if (($CurrentDCOMSDDLMachineLaunchRestriction.SDDL -match $DCOMSDDLPartialMatch) -and ($CurrentDCOMSDDLMachineLaunchRestriction.SDDL -notmatch $DCOMSDDLMachineLaunchRestriction))
	{
		$NewDCOMSDDLMachineLaunchRestriction = $CurrentDCOMSDDLMachineLaunchRestriction.SDDL -replace $DCOMSDDLPartialMatch, $DCOMSDDLMachineLaunchRestriction
	}
	else
	{
		$NewDCOMSDDLMachineLaunchRestriction = $CurrentDCOMSDDLMachineLaunchRestriction.SDDL + "(" + $DCOMSDDLMachineLaunchRestriction + ")"
	}
  
	if (($CurrentDCOMSDDLMachineAccessRestriction.SDDL -match $DCOMSDDLPartialMatch) -and ($CurrentDCOMSDDLMachineAccessRestriction.SDDL -notmatch $DCOMSDDLMachineAccessRestriction))
	{
		$NewDCOMSDDLMachineAccessRestriction = $CurrentDCOMSDDLMachineAccessRestriction.SDDL -replace $DCOMSDDLPartialMatch, $DCOMSDDLMachineLaunchRestriction
	}
	else
	{
		$NewDCOMSDDLMachineAccessRestriction = $CurrentDCOMSDDLMachineAccessRestriction.SDDL + "(" + $DCOMSDDLMachineAccessRestriction + ")"
	}

	if (($CurrentDCOMSDDLDefaultLaunchPermission.SDDL -match $DCOMSDDLPartialMatch) -and ($CurrentDCOMSDDLDefaultLaunchPermission.SDDL -notmatch $DCOMSDDLDefaultLaunchPermission))
	{
		$NewDCOMSDDLDefaultLaunchPermission = $CurrentDCOMSDDLDefaultLaunchPermission.SDDL -replace $DCOMSDDLPartialMatch, $DCOMSDDLDefaultLaunchPermission
	}
	else
	{
		$NewDCOMSDDLDefaultLaunchPermission = $CurrentDCOMSDDLDefaultLaunchPermission.SDDL + "(" + $DCOMSDDLDefaultLaunchPermission + ")"
	}

	if (($CurrentDCOMSDDLDefaultAccessPermission.SDDL -match $DCOMSDDLPartialMatch) -and ($CurrentDCOMSDDLDefaultAccessPermission.SDDL -notmatch $DCOMSDDLDefaultAccessPermision))
	{
		$NewDCOMSDDLDefaultAccessPermission = $CurrentDCOMSDDLDefaultAccessPermission.SDDL -replace $DCOMSDDLPartialMatch, $DCOMSDDLDefaultAccessPermision
	}
	else
	{
		$NewDCOMSDDLDefaultAccessPermission = $CurrentDCOMSDDLDefaultAccessPermission.SDDL + "(" + $DCOMSDDLDefaultAccessPermision + ")"
	}

	# Convert SDDL back to Binary
	Write-Host "`tConverting SDDL back into binary form..."
	$DCOMbinarySDMachineLaunchRestriction = $converter.SDDLToBinarySD($NewDCOMSDDLMachineLaunchRestriction)
	$DCOMconvertedPermissionsMachineLaunchRestriction = ,$DCOMbinarySDMachineLaunchRestriction.BinarySD

	$DCOMbinarySDMachineAccessRestriction = $converter.SDDLToBinarySD($NewDCOMSDDLMachineAccessRestriction)
	$DCOMconvertedPermissionsMachineAccessRestriction = ,$DCOMbinarySDMachineAccessRestriction.BinarySD

	$DCOMbinarySDDefaultLaunchPermission = $converter.SDDLToBinarySD($NewDCOMSDDLDefaultLaunchPermission)
	$DCOMconvertedPermissionDefaultLaunchPermission = ,$DCOMbinarySDDefaultLaunchPermission.BinarySD

	$DCOMbinarySDDefaultAccessPermission = $converter.SDDLToBinarySD($NewDCOMSDDLDefaultAccessPermission)
	$DCOMconvertedPermissionsDefaultAccessPermission = ,$DCOMbinarySDDefaultAccessPermission.BinarySD

	# Apply the changes
	Write-Host "`tApplying changes..."
	if ($CurrentDCOMSDDLMachineLaunchRestriction.SDDL -match $DCOMSDDLMachineLaunchRestriction)
	{
		Write-Host "`t`tCurrent MachineLaunchRestriction matches desired value."
	}
	else
	{
		$result = $Reg.SetBinaryValue(2147483650,"software\microsoft\ole","MachineLaunchRestriction", $DCOMbinarySDMachineLaunchRestriction.binarySD)
		if($result.ReturnValue='0'){Write-Host "`t`tApplied MachineLaunchRestricition complete."}
	}

	if ($CurrentDCOMSDDLMachineAccessRestriction.SDDL -match $DCOMSDDLMachineAccessRestriction)
	{
		Write-Host "`t`tCurrent MachineAccessRestriction matches desired value."
	}
	else
	{
		$result = $Reg.SetBinaryValue(2147483650,"software\microsoft\ole","MachineAccessRestriction", $DCOMbinarySDMachineAccessRestriction.binarySD)
		if($result.ReturnValue='0'){Write-Host "`t`tApplied MachineAccessRestricition complete."}
	}

	if ($CurrentDCOMSDDLDefaultLaunchPermission.SDDL -match $DCOMSDDLDefaultLaunchPermission)
	{
		Write-Host "`t`tCurrent DefaultLaunchPermission matches desired value."
	}
	else
	{
		$result = $Reg.SetBinaryValue(2147483650,"software\microsoft\ole","DefaultLaunchPermission", $DCOMbinarySDDefaultLaunchPermission.binarySD)
		if($result.ReturnValue='0'){Write-Host "`t`tApplied DefaultLaunchPermission complete."}
	}

	if ($CurrentDCOMSDDLDefaultAccessPermission.SDDL -match $DCOMSDDLDefaultAccessPermision)
	{
		Write-Host "`t`tCurrent DefaultAccessPermission matches desired value."
	}
	else
	{
		$result = $Reg.SetBinaryValue(2147483650,"software\microsoft\ole","DefaultAccessPermission", $DCOMbinarySDDefaultAccessPermission.binarySD)
		if($result.ReturnValue='0'){Write-Host "`t`tApplied DefaultAccessPermission complete."}
	}
}

if ($Step6 -or $All)
{
	Write-Host "STEP 6: Update the “Password Reset Users Set” in the FIM Portal to ensure it contains all the users you would like to participate in password reset."
	Write-Host "FIM contains default sets for password reset. Open the Password Reset Users Set in the FIM portal to make sure it contains the users that you would like to participate in password reset."
	Write-Host "THIS IS A MANUAL STEP: Follow guide"
}

if ($Step7 -or $All)
{
	Write-Host "STEP 7: Update the Password reset AuthN workflow in the FIM Portal"
	Write-Host "There is a default workflow in the FIM Portal for password reset that defines the challenges a user must pass before resetting his or her password."
	Write-Host "THIS IS A MANUAL STEP: Follow guide"
}

if ($Step8 -or $All)
{
	Import-Module (Join-Path $PWD "FIM-Modules.psm1") -Force
	If(@(Get-PSSnapin | Where-Object {$_.Name -eq "FIMAutomation"} ).count -eq 0) {Add-PSSnapin FIMAutomation}

	$MPRs = @("Anonymous users can reset their password","Password reset users can read password reset objects","Users can create registration objects for themselves","Password Reset Users can update the lockout attributes of themselves","User management: Users can read attributes of their own","General: Users can read non-administrative configuration resources")
	foreach ($MPR in $MPRs) { Enable-MPR -MPRName $MPR }
}	
