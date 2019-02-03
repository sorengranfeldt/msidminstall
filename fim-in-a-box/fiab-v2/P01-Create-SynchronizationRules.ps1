# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# January 11, 2012 | Soren Granfeldt
#	- initial version

.\Common-InitializeScript.ps1

Import-Module (Join-Path $PWD "FIM-Modules.psm1") -Force
If(@(Get-PSSnapin | Where-Object {$_.Name -eq "FIMAutomation"} ).count -eq 0) {Add-PSSnapin FIMAutomation}

Write-Host "Getting AD MA information"
$global:ADMAObject = Export-FIMConfig -Uri $URI –OnlyBaseResources -CustomConfig ("/ma-data[DisplayName='AD']") 
$ADMAObjectID = $ADMAObject.ResourceManagementObject.ResourceManagementAttributes | ? {$_.AttributeName -eq 'ObjectID' } | Select -Expand Value

$SyncRuleName = $Settings.FIAB.SynchronizationRules.UsersToPortalName
$ExportObject = Export-FIMConfig -Uri $URI –OnlyBaseResources -CustomConfig "/SynchronizationRule[DisplayName='$SyncRuleName']"
If(!$ExportObject) {
	$NewSyncRule = CreateObject -objectType "SynchronizationRule"
	SetAttribute -object $NewSyncRule -AttributeName  "DisplayName" -AttributeValue $SyncRuleName
	SetAttribute -object $NewSyncRule -AttributeName  "Description" -AttributeValue "FIM-in-a-Box"
	SetAttribute -object $NewSyncRule -AttributeName  "ConnectedObjectType" -AttributeValue "user"
	SetAttribute -object $NewSyncRule -AttributeName  "FlowType" -AttributeValue 0
	SetAttribute -object $NewSyncRule -AttributeName  "CreateConnectedSystemObject" -AttributeValue $false
	SetAttribute -object $NewSyncRule -AttributeName  "CreateILMObject" -AttributeValue $true
	SetAttribute -object $NewSyncRule -AttributeName  "DisconnectConnectedSystemObject" -AttributeValue $false
	SetAttribute -object $NewSyncRule -AttributeName  "Precedence" -AttributeValue 1
	SetAttribute -object $NewSyncRule -AttributeName  "ILMObjectType" -AttributeValue "person"
	SetAttribute -object $NewSyncRule -AttributeName  "ManagementAgentID" -AttributeValue "$ADMAObjectID"
	SetAttribute -object $NewSyncRule -AttributeName  "RelationshipCriteria" -AttributeValue "<conditions><condition><ilmAttribute>accountName</ilmAttribute><csAttribute>sAMAccountName</csAttribute></condition></conditions>"
	AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<import-flow><src><attr>sAMAccountName</attr></src><dest>accountName</dest><scoping></scoping></import-flow>"
	AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<import-flow><src><attr>displayName</attr></src><dest>displayName</dest><scoping></scoping></import-flow>"
	AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<import-flow><src><attr>givenName</attr></src><dest>firstName</dest><scoping></scoping></import-flow>"
	AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<import-flow><src><attr>objectSid</attr></src><dest>objectSid</dest><scoping></scoping></import-flow>"
	AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<import-flow><src><attr>sn</attr></src><dest>lastName</dest><scoping></scoping></import-flow>"
	AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<import-flow><src>$DomainNetBIOSName</src><dest>domain</dest><scoping></scoping></import-flow>"

	$NewSyncRule | Import-FIMConfig -uri $URI
	Write-Host "`nSynchronization Rule '$SyncRuleName' created successfully`n"
}
else
{
	Write-Host "`nSynchronization Rule '$SyncRuleName' already exists`n"
}

$SyncRuleName = $Settings.FIAB.SynchronizationRules.UsersToADName
$ExportObject = Export-FIMConfig -Uri $URI –OnlyBaseResources -CustomConfig "/SynchronizationRule[DisplayName='$SyncRuleName']"
If(!$ExportObject) {
	$NewSyncRule = CreateObject -objectType "SynchronizationRule"
	SetAttribute -object $NewSyncRule -AttributeName  "DisplayName" -AttributeValue $SyncRuleName
	SetAttribute -object $NewSyncRule -AttributeName  "Description" -AttributeValue "FIM-in-a-Box"
	SetAttribute -object $NewSyncRule -AttributeName  "ConnectedObjectType" -AttributeValue "user"
	SetAttribute -object $NewSyncRule -AttributeName  "FlowType" -AttributeValue 2
	SetAttribute -object $NewSyncRule -AttributeName  "CreateConnectedSystemObject" -AttributeValue $true
	SetAttribute -object $NewSyncRule -AttributeName  "CreateILMObject" -AttributeValue $false
	SetAttribute -object $NewSyncRule -AttributeName  "DisconnectConnectedSystemObject" -AttributeValue $false
	SetAttribute -object $NewSyncRule -AttributeName  "Precedence" -AttributeValue 1
	SetAttribute -object $NewSyncRule -AttributeName  "ILMObjectType" -AttributeValue "person"
	SetAttribute -object $NewSyncRule -AttributeName  "ManagementAgentID" -AttributeValue "$ADMAObjectID"
	SetAttribute -object $NewSyncRule -AttributeName  "RelationshipCriteria" -AttributeValue "<conditions><condition><ilmAttribute>accountName</ilmAttribute><csAttribute>sAMAccountName</csAttribute></condition></conditions>"
	
	AddMultiValue -object $NewSyncRule -AttributeName  "InitialFlow" -AttributeValue "<export-flow allows-null=""false""><src><attr>accountName</attr></src><dest>dn</dest><scoping></scoping><fn id=""+"" isCustomExpression=""true""><arg><fn id=""EscapeDNComponent"" isCustomExpression=""false""><arg><fn id=""+"" isCustomExpression=""false""><arg>""CN=""</arg><arg>accountName</arg></fn></arg></fn></arg><arg>"",$($Settings.FIAB.General.ManagedOU)""</arg><arg>"",$DefaultNamingContext""</arg></fn></export-flow>"
	AddMultiValue -object $NewSyncRule -AttributeName  "InitialFlow" -AttributeValue "<export-flow allows-null='false'><src>512</src><dest>userAccountControl</dest><scoping></scoping></export-flow>"
	AddMultiValue -object $NewSyncRule -AttributeName  "InitialFlow" -AttributeValue "<export-flow allows-null='false'><src>Password2012</src><dest>unicodePwd</dest><scoping></scoping></export-flow>"
	AddMultiValue -object $NewSyncRule -AttributeName  "InitialFlow" -AttributeValue "<export-flow allows-null='false'><src><attr>accountName</attr></src><dest>sAMAccountName</dest><scoping></scoping></export-flow>"
	
	AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<export-flow allows-null='false'><src><attr>accountName</attr></src><dest>sAMAccountName</dest><scoping></scoping></export-flow>"
	AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<export-flow allows-null='false'><src><attr>displayName</attr></src><dest>displayName</dest><scoping></scoping></export-flow>"
	AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<export-flow allows-null='false'><src><attr>firstName</attr></src><dest>givenName</dest><scoping></scoping></export-flow>"
	AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<export-flow allows-null='false'><src><attr>lastName</attr></src><dest>sn</dest><scoping></scoping></export-flow>"
	AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<import-flow><src><attr>mail</attr></src><dest>mail</dest><scoping></scoping></import-flow>"

	$NewSyncRule | Import-FIMConfig -uri $URI
	Write-Host "`nSynchronization Rule '$SyncRuleName' created successfully`n"
}
else
{
	Write-Host "`nSynchronization Rule '$SyncRuleName' already exists`n"
}

$SyncRuleName = $Settings.FIAB.SynchronizationRules.GroupsToADName
$ExportObject = Export-FIMConfig -Uri $URI –OnlyBaseResources -CustomConfig "/SynchronizationRule[DisplayName='$SyncRuleName']"
If(!$ExportObject) {
	$NewSyncRule = CreateObject -objectType "SynchronizationRule"
	SetAttribute -object $NewSyncRule -AttributeName  "DisplayName" -AttributeValue $SyncRuleName
	SetAttribute -object $NewSyncRule -AttributeName  "Description" -AttributeValue "FIM-in-a-Box"
	SetAttribute -object $NewSyncRule -AttributeName  "ConnectedObjectType" -AttributeValue "group"
	SetAttribute -object $NewSyncRule -AttributeName  "FlowType" -AttributeValue 2
	SetAttribute -object $NewSyncRule -AttributeName  "CreateConnectedSystemObject" -AttributeValue $true
	SetAttribute -object $NewSyncRule -AttributeName  "CreateILMObject" -AttributeValue $false
	SetAttribute -object $NewSyncRule -AttributeName  "DisconnectConnectedSystemObject" -AttributeValue $false
	SetAttribute -object $NewSyncRule -AttributeName  "Precedence" -AttributeValue 1
	SetAttribute -object $NewSyncRule -AttributeName  "ILMObjectType" -AttributeValue "group"
	SetAttribute -object $NewSyncRule -AttributeName  "ManagementAgentID" -AttributeValue "$ADMAObjectID"
	SetAttribute -object $NewSyncRule -AttributeName  "RelationshipCriteria" -AttributeValue "<conditions><condition><ilmAttribute>accountName</ilmAttribute><csAttribute>sAMAccountName</csAttribute></condition></conditions>"
	
	AddMultiValue -object $NewSyncRule -AttributeName  "InitialFlow" -AttributeValue "<export-flow allows-null=""false""><src><attr>displayName</attr></src><dest>dn</dest><scoping></scoping><fn id=""+"" isCustomExpression=""true""><arg><fn id=""EscapeDNComponent"" isCustomExpression=""false""><arg><fn id=""+"" isCustomExpression=""false""><arg>""CN=""</arg><arg>displayName</arg></fn></arg></fn></arg><arg>"",$($Settings.FIAB.General.ManagedOU)""</arg><arg>"",$DefaultNamingContext""</arg></fn></export-flow>"
	
	AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<export-flow allows-null='false'><src><attr>displayName</attr></src><dest>displayName</dest><scoping></scoping></export-flow>"
	AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<export-flow allows-null='true'><src><attr>member</attr></src><dest>member</dest><scoping></scoping></export-flow>"
	AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<export-flow allows-null='false'><src><attr>displayedOwner</attr></src><dest>managedBy</dest><scoping></scoping></export-flow>"
	AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<import-flow><src><attr>mail</attr></src><dest>mail</dest><scoping></scoping></import-flow>"
	AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<export-flow allows-null='false'><src><attr>type</attr><attr>scope</attr></src><dest>groupType</dest><scoping></scoping><fn id=""IIF"" isCustomExpression=""true""><arg><fn id=""Eq"" isCustomExpression=""false""><arg>type</arg><arg>""Distribution""</arg></fn></arg><arg><fn id=""IIF"" isCustomExpression=""false""><arg><fn id=""Eq"" isCustomExpression=""false""><arg>scope</arg><arg>""Universal""</arg></fn></arg><arg>8</arg><arg><fn id=""IIF"" isCustomExpression=""false""><arg><fn id=""Eq"" isCustomExpression=""false""><arg>scope</arg><arg>""Global""</arg></fn></arg><arg>2</arg><arg>4</arg></fn></arg></fn></arg><arg><fn id=""IIF"" isCustomExpression=""false""><arg><fn id=""Eq"" isCustomExpression=""false""><arg>scope</arg><arg>""Universal""</arg></fn></arg><arg>-2147483640</arg><arg><fn id=""IIF"" isCustomExpression=""false""><arg><fn id=""Eq"" isCustomExpression=""false""><arg>scope</arg><arg>""Global""</arg></fn></arg><arg>-2147483646</arg><arg>-2147483644</arg></fn></arg></fn></arg></fn></export-flow>"
	
	# ONLY FOR EXCHANGE (detect through schema)
	if ($HasExchange)
	{
		AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<export-flow allows-null='false'><src><attr>mailNickName</attr></src><dest>mailNickName</dest><scoping></scoping></export-flow>"
		AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<export-flow allows-null='false'><src><attr>accountName</attr><attr>mailNickname</attr></src><dest>sAMAccountName</dest><scoping></scoping><fn id=""IIF"" isCustomExpression=""true""><arg><fn id=""IsPresent"" isCustomExpression=""false""><arg>accountName</arg></fn></arg><arg>accountName</arg><arg>mailNickname</arg></fn></export-flow>"
	}
	else
	{
		AddMultiValue -object $NewSyncRule -AttributeName  "PersistentFlow" -AttributeValue "<export-flow allows-null='false'><src><attr>accountName</attr></src><dest>sAMAccountName</dest><scoping></scoping></export-flow>"
	}

	$NewSyncRule | Import-FIMConfig -uri $URI
	Write-Host "`nSynchronization Rule '$SyncRuleName' created successfully`n"
}
else
{
	Write-Host "`nSynchronization Rule '$SyncRuleName' already exists`n"
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
