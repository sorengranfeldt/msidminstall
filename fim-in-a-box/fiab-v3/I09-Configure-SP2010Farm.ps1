# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# June 29, 2012 | Soren Granfeldt
#	- initial version

$Activity = "Configuring SharePoint Foundation 2010 farm"

Import-Module .\FIAB-Module.psm1 -Force

Write-Progress -Id 1 -Activity $Activity -status "Loading SharePoint snap-ins"
if (-not (Get-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue)) { Add-PsSnapin Microsoft.SharePoint.PowerShell }

# The farm passphrase is a new security feature in SharePoint Foundation 2010. Similar to a password, 
# it is created as part of the initial creation of a SharePoint farm (or as a part of upgrade). 
# The passphrase is created during PSConfig portion of SharePoint installation. It is then only required 
# for adding additional servers to the farm.
$Passphrase = ConvertTo-SecureString $SPFarmPassphrase -AsPlainText -Force

Write-Progress -Id 1 -Activity $Activity -status "Creating farm credentials"
$SecurePassword = ConvertTo-SecureString $SPConfigServiceServiceAccountPassword -AsPlainText -Force
$FarmAcct = New-Object System.Management.Automation.PSCredential ($SPConfigServiceServiceAccount, $SecurePassword)

Write-Progress -Id 1 -Activity $Activity -status "Creating databases $SPConfigurationDatabase and $SPAdminContentDatabase on $SQLServerWithInstance"
$params = @{
	DatabaseName = $SPConfigurationDatabase # this will also be the farm name
	DatabaseServer = $SQLServerWithInstance
	AdministrationContentDatabaseName = $SPAdminContentDatabase
	Passphrase = $Passphrase
	FarmCredentials = $FarmAcct
}
New-SPConfigurationDatabase @params -ErrorAction SilentlyContinue -ErrorVariable err

# The Initialize-SPResourceSecurity cmdlet enforces resource security on the local server. This cmdlet enforces security for all resources, including files, folders, and registry keys.
Write-Progress -Id 1 -Activity $Activity -status "Enforcing resource security"
Initialize-SPResourceSecurity

# The Install-SPService cmdlet installs and optionally provisions services on a farm. This cmdlet installs all services, service instances, and service proxies specified in the registry on the local server computer. Use this cmdlet in a script that you build to install and deploy a SharePoint farm or to install a custom developed service.
Write-Progress -Id 1 -Activity $Activity -status "Provisioning services"
Install-SPService

# The Install-SPFeature cmdlet installs a specific SPFeature object by providing in the Identity parameter the relative path from the folder "$env:ProgramFiles\Common Files\Microsoft Shared\Web Server Extensions\14\TEMPLATE\FEATURES\ to the feature. The SharePoint Feature’s files must already be put in the proper directory, either manually or by using a solution installer.
# If the AllExistingFeatures parameter is provided, the file system is scanned and any new features are installed. This is generally only used during deployment and upgrade.
Write-Progress -Id 1 -Activity $Activity -status "Installing features"
Install-SPFeature -AllExistingFeatures

# Creates a new Central Administration Web application and starts the central administration service on the local computer. Central Administration is available only on computers where this service runs.
Write-Progress -Id 1 -Activity $Activity -status "Creating Central Administration Web"
New-SPCentralAdministration -Port $CentralAdminWebApplicationPortNumber -WindowsAuthProvider $SPAuthentication

# Installs the Help site collection files for SharePoint 2010 Products in the current farm. 
Write-Progress -Id 1 -Activity $Activity -status "Installing Help site collection files"
Install-SPHelpCollection -All

# Copies shared application data to existing Web application folders.
Write-Progress -Id 1 -Activity $Activity -status "Copying shared application data to existing Web application folders"
Install-SPApplicationContent
