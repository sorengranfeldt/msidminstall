# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# January 11, 2012 | Soren Granfeldt
#	- initial version

.\Common-InitializeScript.ps1

Import-Module (Join-Path $PWD "FIM-Modules.psm1") -Force
If(@(Get-PSSnapin | Where-Object {$_.Name -eq "FIMAutomation"} ).count -eq 0) {Add-PSSnapin FIMAutomation}

Write-Host "Getting Sync Rule '$($Settings.FIAB.SynchronizationRules.UsersToADName)' information"
$global:SRObject = Export-FIMConfig -Uri $URI –OnlyBaseResources -CustomConfig ("/SynchronizationRule[DisplayName='$($Settings.FIAB.SynchronizationRules.UsersToADName)']") 
$SRObjectID = ($SRObject.ResourceManagementObject.ResourceManagementAttributes | ? {$_.AttributeName -eq 'ObjectID' } | Select -Expand Value) -replace '^urn\:uuid\:', ''
$WorkflowName = $Settings.FIAB.Workflows.AddUserToAD
$ExportObject = Export-FIMConfig -Uri $URI –OnlyBaseResources -CustomConfig "/WorkflowDefinition[DisplayName='$WorkflowName']"
If(!$ExportObject) {
	$NewWorkflow = CreateObject -objectType "WorkflowDefinition"
	SetAttribute -object $NewWorkflow -AttributeName  "DisplayName" -AttributeValue $WorkflowName
	SetAttribute -object $NewWorkflow -AttributeName  "Description" -AttributeValue "FIM-in-a-Box"
	SetAttribute -object $NewWorkflow -AttributeName  "RequestPhase" -AttributeValue "Action"
	SetAttribute -object $NewWorkflow -AttributeName  "RunOnPolicyUpdate" -AttributeValue $true
	$XOML = "<ns0:SequentialWorkflow x:Name=""SequentialWorkflow"" ActorId=""00000000-0000-0000-0000-000000000000"" WorkflowDefinitionId=""00000000-0000-0000-0000-000000000000"" RequestId=""00000000-0000-0000-0000-000000000000"" TargetId=""00000000-0000-0000-0000-000000000000"" xmlns:x=""http://schemas.microsoft.com/winfx/2006/xaml"" xmlns:ns0=""clr-namespace:Microsoft.ResourceManagement.Workflow.Activities;Assembly=Microsoft.ResourceManagement, Version=4.0.2592.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"">" + `
            "<ns0:SynchronizationRuleActivity RemoveValue=""{x:Null}"" AttributeId=""00000000-0000-0000-0000-000000000000"" AddValue=""{x:Null}"" x:Name=""authenticationGateActivity1"" SynchronizationRuleId=""$SRObjectID"" Action=""Add"">" + `
            "<ns0:SynchronizationRuleActivity.Parameters>" + `
			"<x:Array Type=""{x:Type ns0:SynchronizationRuleParameter}"" />" + `
			"</ns0:SynchronizationRuleActivity.Parameters>" + `
			"</ns0:SynchronizationRuleActivity>" + `
			"</ns0:SequentialWorkflow>"

	SetAttribute -object $NewWorkflow -AttributeName  "XOML" -AttributeValue $XOML
	$NewWorkflow | Import-FIMConfig -uri $URI
	Write-Host "Workflow '$WorkflowName' created successfully"
}
else
{
	Write-Host "Workflow '$WorkflowName' already exists"
}
Write-Host "Getting Sync Rule '$($Settings.FIAB.SynchronizationRules.GroupsToADName)' information"
$global:SRObject = Export-FIMConfig -Uri $URI –OnlyBaseResources -CustomConfig ("/SynchronizationRule[DisplayName='$($Settings.FIAB.SynchronizationRules.GroupsToADName)']") 
$SRObjectID = ($SRObject.ResourceManagementObject.ResourceManagementAttributes | ? {$_.AttributeName -eq 'ObjectID' } | Select -Expand Value) -replace '^urn\:uuid\:', ''
$WorkflowName = $Settings.FIAB.Workflows.AddGroupToAD
$ExportObject = Export-FIMConfig -Uri $URI –OnlyBaseResources -CustomConfig "/WorkflowDefinition[DisplayName='$WorkflowName']"
If(!$ExportObject) {
	$NewWorkflow = CreateObject -objectType "WorkflowDefinition"
	SetAttribute -object $NewWorkflow -AttributeName  "DisplayName" -AttributeValue $WorkflowName
	SetAttribute -object $NewWorkflow -AttributeName  "Description" -AttributeValue "FIM-in-a-Box"
	SetAttribute -object $NewWorkflow -AttributeName  "RequestPhase" -AttributeValue "Action"
	SetAttribute -object $NewWorkflow -AttributeName  "RunOnPolicyUpdate" -AttributeValue $false
	$XOML = "<ns0:SequentialWorkflow x:Name=""SequentialWorkflow"" ActorId=""00000000-0000-0000-0000-000000000000"" WorkflowDefinitionId=""00000000-0000-0000-0000-000000000000"" RequestId=""00000000-0000-0000-0000-000000000000"" TargetId=""00000000-0000-0000-0000-000000000000"" xmlns:x=""http://schemas.microsoft.com/winfx/2006/xaml"" xmlns:ns0=""clr-namespace:Microsoft.ResourceManagement.Workflow.Activities;Assembly=Microsoft.ResourceManagement, Version=4.0.2592.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35"">" + `
            "<ns0:SynchronizationRuleActivity RemoveValue=""{x:Null}"" AttributeId=""00000000-0000-0000-0000-000000000000"" AddValue=""{x:Null}"" x:Name=""authenticationGateActivity1"" SynchronizationRuleId=""$SRObjectID"" Action=""Add"">" + `
            "<ns0:SynchronizationRuleActivity.Parameters>" + `
			"<x:Array Type=""{x:Type ns0:SynchronizationRuleParameter}"" />" + `
			"</ns0:SynchronizationRuleActivity.Parameters>" + `
			"</ns0:SynchronizationRuleActivity>" + `
			"</ns0:SequentialWorkflow>"

	SetAttribute -object $NewWorkflow -AttributeName  "XOML" -AttributeValue $XOML
	$NewWorkflow | Import-FIMConfig -uri $URI
	Write-Host "Workflow '$WorkflowName' created successfully"
}
else
{
	Write-Host "Workflow '$WorkflowName' already exists"
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
