# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# January 12, 2012 | Soren Granfeldt
#	- initial version
# March 27, 2012 | Soren Granfeldt
#	- fixed the value of DomainNetBIOSName to extract first element, since this may be an array/collection if multiple domains are present

.\Common-InitializeScript.ps1

$MADir = (Join-Path $PWD "ManagementAgents")
New-Item -Type Directory -Path $MADir -Force | Out-Null

$ADMATemplateFilename = "ADMA-Template.xml"
$FIMMATemplateFilename = "FIMMA-Template.xml"

$MA = New-Object XML
$MA.Load((Join-Path $PWD "ConfigurationFiles\$($ADMATemplateFilename)"))

$MA."export-ma"."ma-data"."private-configuration"."adma-configuration"."forest-name" = $MA."export-ma"."ma-data"."private-configuration"."adma-configuration"."forest-name" -Replace '###FIABForestFQDN###', $FQDN.Name
$MA."export-ma"."ma-data"."private-configuration"."adma-configuration"."forest-login-domain" = $MA."export-ma"."ma-data"."private-configuration"."adma-configuration"."forest-login-domain" -Replace '###FIABDomainNetBIOSName###', $DomainNetBIOSName
$MA."export-ma"."ma-data"."private-configuration"."adma-configuration"."forest-login-user" = $MA."export-ma"."ma-data"."private-configuration"."adma-configuration"."forest-login-user" -Replace '###FIABManagementAgentADAccount###', $Settings.FIAB.General.ServiceAccounts.ManagementAgentAD

$MA."export-ma"."ma-data"."ma-partition-data".partition | % { `
	$_.name = $_.name -Replace '###FIABDomainNamingContext###', $DefaultNamingContext
	$_."custom-data"."adma-partition-data".name = $_."custom-data"."adma-partition-data".name -Replace '###FIABForestFQDN###', $FQDN.Name
	
	foreach ($x in $_."custom-data"."adma-partition-data")
	{
		$x.dn = ($x.dn -Replace '###FIABDomainNamingContext###', $DefaultNamingContext)
	}
	
	if ($_."filter".containers.inclusions.HasChildNodes)
	{
		foreach ($e in $_."filter".containers.inclusions.ChildNodes)
		{
			$e.InnerText = $e.InnerText -Replace '###FIABDomainNamingContext###', $DefaultNamingContext
			$e.InnerText = $e.InnerText -Replace '###FIABManagedOU###', $Settings.FIAB.General.ManagedOU
		}
	}

	if ($_."filter".containers.exclusions.HasChildNodes)
	{
		foreach ($e in $_."filter".containers.exclusions.ChildNodes)
		{
			$e.InnerText = $e.InnerText -Replace '###FIABDomainNamingContext###', $DefaultNamingContext
		}
	}
}
$MA.Save((Join-Path $MADir 'AD-ManagementAgent.XML'))
Write-Host "Created AD Management Agent in '$(Join-Path $MADir 'AD-ManagementAgent.XML')'"

$MA = New-Object XML
$MA.Load((Join-Path $PWD "ConfigurationFiles\$($FIMMATemplateFilename)"))

$MA."export-ma"."ma-data"."private-configuration"."fimma-configuration"."connection-info"."server" = ("$($Settings.FIAB.SQLServer.SQLServer)\$($Settings.FIAB.SQLServer.SQLServerInstance)" -Replace "\\$", "")
$MA."export-ma"."ma-data"."private-configuration"."fimma-configuration"."connection-info"."user" = $Settings.FIAB.General.ServiceAccounts.ManagementAgentFIM
$MA."export-ma"."ma-data"."private-configuration"."fimma-configuration"."connection-info"."domain" = $DomainNetBIOSName[0]
$MA."export-ma"."ma-data"."private-configuration"."fimma-configuration"."connection-info"."serviceHost" = $MA."export-ma"."ma-data"."private-configuration"."fimma-configuration"."connection-info"."serviceHost" -Replace "###FIABQualifiedServiceVirtualName###", $Settings.FIAB.General.QualifiedServiceVirtualName

$MA.Save((Join-Path $MADir 'FIM-ManagementAgent.XML'))
Write-Host "Created FIM Management Agent in '$(Join-Path $MADir 'FIM-ManagementAgent.XML')'"

.\Common-TerminateScript.ps1