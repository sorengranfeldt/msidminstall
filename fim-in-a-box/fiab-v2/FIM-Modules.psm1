# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# December 15, 2011 | Soren Granfeldt
#	- initial version
# March 29, 2012 | Soren Granfeldt
#	- change Enable-MPR function to allow for duplicate displaynames (now doing ForEach-Object)

#----------------------------------------------------------------------------------------------------------
 Function SetAttribute
 {
    Param($object, $attributeName, $attributeValue)
    End
    {
        $importChange = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportChange
        $importChange.Operation = 1
        $importChange.AttributeName = $attributeName
        $importChange.AttributeValue = $attributeValue
        $importChange.FullyResolved = 1
        $importChange.Locale = "Invariant"
        If ($object.Changes -eq $null) {$object.Changes = (,$importChange)}
        Else {$object.Changes += $importChange}
    }
} 
#----------------------------------------------------------------------------------------------------------
 Function CreateObject
 {
    Param($objectType)
    End
    {
       $newObject = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject
       $newObject.ObjectType = $objectType
       $newObject.SourceObjectIdentifier = [System.Guid]::NewGuid().ToString()
       $newObject
     } 
 }
#----------------------------------------------------------------------------------------------------------
Function AddMultiValue
 {
 Param($object, $attributeName, $attributeValue)
 End
 {
  $importChange = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportChange
  $importChange.Operation = 0
  $importChange.AttributeName = $attributeName
  $importChange.AttributeValue = $attributeValue
  $importChange.FullyResolved = 1
  $importChange.Locale = "Invariant"
  If ($object.Changes -eq $null) {$object.Changes = (,$importChange)}
  Else {$object.Changes += $importChange}
 }
}
#----------------------------------------------------------------------------------------------------------
function Enable-MPR($MPRName)
{
	Write-Host "Enabling MPR '$MPRName'"
	$ExportedObject = export-fimconfig -uri $URI –onlyBaseResources -customconfig ("/ManagementPolicyRule[DisplayName='$MPRName']")

	if ($ExportedObject -eq $null) {throw "MPR '$MPRName' not found!"} 
	$ExportedObject | % { `
		$ObjectType = $_.ResourceManagementObject.ObjectType 
		$ObjectIdentifier = $_.ResourceManagementObject.ObjectIdentifier 
		$CurrentValue = $_.ResourceManagementObject.ResourceManagementAttributes | Where-Object {$_.AttributeName -eq "Disabled"}
	 
		if ($CurrentValue.Value -eq "False") 
		{
			Write-Host "MPR '$MPRName' is already enabled"
		}
		else
		{
			$ImportChange = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportChange
			$ImportChange.Operation = 1
			$ImportChange.AttributeName = "Disabled"
			$ImportChange.AttributeValue = "False"
			$ImportChange.FullyResolved = 1
			$ImportChange.Locale = "Invariant"

			$ImportObject = New-Object Microsoft.ResourceManagement.Automation.ObjectModel.ImportObject
			$ImportObject.ObjectType = $ObjectType
			$ImportObject.TargetObjectIdentifier = $ObjectIdentifier
			$ImportObject.SourceObjectIdentifier = $ObjectIdentifier
			$ImportObject.State = 1 
			$ImportObject.Changes = (,$ImportChange)

			$ImportObject | Import-FIMConfig -uri $URI
	  
			Write-Host "MPR '$MPRName' enabled successfully"
		}
	}
}
#----------------------------------------------------------------------------------------------------------
$global:URI = "http://$($Settings.FIAB.General.QualifiedServiceVirtualName):5725/resourcemanagementservice"
