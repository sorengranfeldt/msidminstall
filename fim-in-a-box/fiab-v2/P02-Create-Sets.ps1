# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# January 11, 2012 | Soren Granfeldt
#	- initial version
# February 23, 2012 | Soren Granfeldt
#	- change filter for All People set to exclude current user (installation account)
# March 28, 2012 | Soren Granfeldt
#	- removed typo for Set name resulting in error creating MPR

.\Common-InitializeScript.ps1

Import-Module (Join-Path $PWD "FIM-Modules.psm1") -Force
If(@(Get-PSSnapin | Where-Object {$_.Name -eq "FIMAutomation"} ).count -eq 0) {Add-PSSnapin FIMAutomation}

$global:SRObject = Export-FIMConfig -Uri $URI –OnlyBaseResources -CustomConfig ("/Person[DisplayName='$ShortUserName']")
$CurrentUserGuid = ($SRObject.ResourceManagementObject.ResourceManagementAttributes | ? {$_.AttributeName -eq 'ObjectID' } | Select -Expand Value) -replace '^urn\:uuid\:', ''

$Setname = $Settings.FIAB.Sets.AllPeople
$ExportObject = Export-FIMConfig -Uri $URI –OnlyBaseResources -CustomConfig "/Set[DisplayName='$Setname']"
If(!$ExportObject) {
	$NewSet = CreateObject -objectType "Set"
	SetAttribute -object $NewSet -AttributeName  "DisplayName" -AttributeValue $Setname
	SetAttribute -object $NewSet -AttributeName  "Description" -AttributeValue "FIM-in-a-Box"
	$Filter = "<Filter xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"" " + `
			"Dialect=""http://schemas.microsoft.com/2006/11/XPathFilterDialect"" xmlns=""http://schemas.xmlsoap.org/ws/2004/09/enumeration"">" + `
			"/Person[not(ObjectID = 'fb89aefa-5ea1-47f1-8890-abe7797d6497') and not(ObjectID = '$CurrentUserGuid')]" + `
			"</Filter>"

	SetAttribute -object $NewSet -AttributeName  "Filter" -AttributeValue $Filter
	$NewSet | Import-FIMConfig -uri $URI
	Write-Host "Set '$Setname' created successfully"
}
else
{
	Write-Host "Set '$Setname' already exists"
}

$Setname = $Settings.FIAB.Sets.AllGroups
$ExportObject = Export-FIMConfig -Uri $URI –OnlyBaseResources -CustomConfig "/Set[DisplayName='$Setname']"
If(!$ExportObject) {
	$NewSet = CreateObject -objectType "Set"
	SetAttribute -object $NewSet -AttributeName  "DisplayName" -AttributeValue $Setname
	SetAttribute -object $NewSet -AttributeName  "Description" -AttributeValue "FIM-in-a-Box"
	$Filter = "<Filter xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"" xmlns:xsd=""http://www.w3.org/2001/XMLSchema"" " + `
			"Dialect=""http://schemas.microsoft.com/2006/11/XPathFilterDialect"" xmlns=""http://schemas.xmlsoap.org/ws/2004/09/enumeration"">" + `
			"/Group" + `
			"</Filter>"

	SetAttribute -object $NewSet -AttributeName  "Filter" -AttributeValue $Filter
	$NewSet | Import-FIMConfig -uri $URI
	Write-Host "Set '$Setname' created successfully"
}
else
{
	Write-Host "Set '$Setname' already exists"
}


.\Common-TerminateScript.ps1

#Trap 
#{ 
#	$exMessage = $_.Exception.Message
#	if($exMessage.StartsWith("L:"))
#	{Write-Host "`n" $exMessage.substring(2) "`n" -foregroundcolor white -backgroundcolor darkblue}
#	else {Write-Host "`nError: " $exMessage "`n" -foregroundcolor white -backgroundcolor darkred}
#	Exit 1
#}
