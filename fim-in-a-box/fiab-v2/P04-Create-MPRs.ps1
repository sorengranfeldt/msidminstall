# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# January 11, 2012 | Soren Granfeldt
#	- initial version

.\Common-InitializeScript.ps1

Import-Module (Join-Path $PWD "FIM-Modules.psm1") -Force
If(@(Get-PSSnapin | Where-Object {$_.Name -eq "FIMAutomation"} ).count -eq 0) {Add-PSSnapin FIMAutomation}

Write-Host "Getting Workflow '$($Settings.FIAB.Workflows.AddUserToAD)' information"
$global:Workflow = Export-FIMConfig -Uri $URI –OnlyBaseResources -CustomConfig ("/WorkflowDefinition[DisplayName='$($Settings.FIAB.Workflows.AddUserToAD)']")
$WorkflowID = ($Workflow.ResourceManagementObject.ResourceManagementAttributes | ? {$_.AttributeName -eq 'ObjectID' } | Select -Expand Value) 

Write-Host "Getting Resource Set '$($Settings.FIAB.Sets.AllPeople)' information"
$global:ResSet = Export-FIMConfig -Uri $URI –OnlyBaseResources -CustomConfig ("/Set[DisplayName='$($Settings.FIAB.Sets.AllPeople)']") 
$ResSetID = ($ResSet.ResourceManagementObject.ResourceManagementAttributes | ? {$_.AttributeName -eq 'ObjectID' } | Select -Expand Value) 

$MPRName = $Settings.FIAB.ManagementPolicyRules.AddUserToADSyncRule
$ExportObject = Export-FIMConfig -Uri $URI –OnlyBaseResources -CustomConfig "/ManagementPolicyRule[DisplayName='$MPRName']"
If(!$ExportObject) {
	$NewMPR = CreateObject -objectType "ManagementPolicyRule"
	SetAttribute -object $NewMPR -AttributeName  "DisplayName" -AttributeValue $MPRName
	SetAttribute -object $NewMPR -AttributeName  "Description" -AttributeValue "FIM-in-a-Box"
	SetAttribute -object $NewMPR -AttributeName  "Disabled" -AttributeValue $true
	SetAttribute -object $NewMPR -AttributeName  "GrantRight" -AttributeValue $false
	SetAttribute -object $NewMPR -AttributeName  "ResourceFinalSet" -AttributeValue "$ResSetID"
	SetAttribute -object $NewMPR -AttributeName  "ManagementPolicyRuleType" -AttributeValue "SetTransition"
	
	AddMultiValue -object $NewMPR -AttributeName  "ActionParameter" -AttributeValue "*"
	AddMultiValue -object $NewMPR -AttributeName  "ActionType" -AttributeValue "TransitionIn"
	AddMultiValue -object $NewMPR -AttributeName  "ActionWorkflowDefinition" -AttributeValue "$WorkflowID"

	$NewMPR | Import-FIMConfig -uri $URI
	Write-Host "Management Policy Rule '$MPRName' created successfully"
}
else
{
	Write-Host "Management Policy Rule '$MPRName' already exists"
}


Write-Host "Getting Workflow '$($Settings.FIAB.Workflows.AddGroupToAD)' information"
$global:Workflow = Export-FIMConfig -Uri $URI –OnlyBaseResources -CustomConfig ("/WorkflowDefinition[DisplayName='$($Settings.FIAB.Workflows.AddGroupToAD)']")
$WorkflowID = ($Workflow.ResourceManagementObject.ResourceManagementAttributes | ? {$_.AttributeName -eq 'ObjectID' } | Select -Expand Value) #-replace '^urn\:uuid\:', ''

Write-Host "Getting Resource Set '$($Settings.FIAB.Sets.AllGroups)' information"
$global:ResSet = Export-FIMConfig -Uri $URI –OnlyBaseResources -CustomConfig ("/Set[DisplayName='$($Settings.FIAB.Sets.AllGroups)']") 
$ResSetID = ($ResSet.ResourceManagementObject.ResourceManagementAttributes | ? {$_.AttributeName -eq 'ObjectID' } | Select -Expand Value) #-replace '^urn\:uuid\:', ''

$MPRName = $Settings.FIAB.ManagementPolicyRules.AddGroupToADSyncRule
$ExportObject = Export-FIMConfig -Uri $URI –OnlyBaseResources -CustomConfig "/ManagementPolicyRule[DisplayName='$MPRName']"
If(!$ExportObject) {
	$NewMPR = CreateObject -objectType "ManagementPolicyRule"
	SetAttribute -object $NewMPR -AttributeName  "DisplayName" -AttributeValue $MPRName
	SetAttribute -object $NewMPR -AttributeName  "Description" -AttributeValue "FIM-in-a-Box"
	SetAttribute -object $NewMPR -AttributeName  "Disabled" -AttributeValue $true
	SetAttribute -object $NewMPR -AttributeName  "GrantRight" -AttributeValue $false
	SetAttribute -object $NewMPR -AttributeName  "ResourceFinalSet" -AttributeValue "$ResSetID"
	SetAttribute -object $NewMPR -AttributeName  "ManagementPolicyRuleType" -AttributeValue "SetTransition"
	
	AddMultiValue -object $NewMPR -AttributeName  "ActionParameter" -AttributeValue "*"
	AddMultiValue -object $NewMPR -AttributeName  "ActionType" -AttributeValue "TransitionIn"
	AddMultiValue -object $NewMPR -AttributeName  "ActionWorkflowDefinition" -AttributeValue "$WorkflowID"

	$NewMPR | Import-FIMConfig -uri $URI
	Write-Host "Management Policy Rule '$MPRName' created successfully"
}
else
{
	Write-Host "Management Policy Rule '$MPRName' already exists"
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
