<#
.SYNOPSIS 
	Installs FIM 2010 R2 Portal and Service and optionally Password Registration and Password Reset portals
.DESCRIPTION
	FIM-in-a-Box Installation and configuration scripts
	Copyright 2010-2012, Microsoft Corporation
.PARAMETER ShowGuidedUI
	If specified, a guided GUI will be shown before installation for user to be able to verify parameters
	before installation
.PARAMETER NoPasswordReset
	If specified, the Password Registration and Password Reset portals will NOT be installed
.PARAMETER IsRegistrationExtranet
    Required. This value specifies if password registration site will be accessible by extranet users. 
		'Extranet': can be accessed by extranet users
		'None': can be accessed only by internal users
.PARAMETER IsResetExtranet
    Required. This value specifies if password reset site will be accessible by extranet users.
		'Extranet': can be accessed by extranet users
		'None': can be accessed only by internal users
.NOTES
	Version History
	July 5, 2012 | Soren Granfeldt
		- revised for FIM R2
#>
PARAM
(
	[switch] $ShowGuidedUI,
	[switch] $NoPasswordReset,
	
	[ValidatePattern("(Extranet|None)")]
	[Parameter(Mandatory=$true)]
	[string] $IsResetExtranet = "Extranet", # could be 'None'
	
	[ValidatePattern("(Extranet|None)")]
	[Parameter(Mandatory=$true)]
	[string] $IsRegistrationExtranet = "Extranet" # could be 'None'
)

if ($ShowGuidedUI) { $QuietParam = "" } else { $QuietParam = "/qn" }

$Activity = "Installing FIM Service and FIM Portal"

Write-Progress -Id 1 -Activity $Activity -status "Importing FIAB module"
Import-Module .\FIAB-Module.psm1 -Force

$MsiFile = Join-Path $SoftwarePath "FIMR2\Service and Portal\Service and Portal.msi"
$LogFile = Join-Path "$PWD"  ("Logs\FIMServiceAndPortal.Installation.{0:yyyyMMdd-HHmmss}.log" -F (Get-Date)) 

$Arguments = 	"$QuietParam /I ""$MsiFile"" /LOG ""$LogFile"" "+ `
				"ADDLOCAL={ADDLOCAL} "+ `
				"ACCEPT_EULA=1 "+ `
				"SQMOPTINSETTING=0 "+ `
				"SQLSERVER_SERVER=$SQLServerWithInstance "+ `
				"SQLSERVER_DATABASE=FIMService "+ `
				"EXISTINGDATABASE=0 "+ `
				"MAIL_SERVER=$MailServer "+ `
				"MAIL_SERVER_USE_SSL=$MailServerUseSSL "+ `
				"MAIL_SERVER_IS_EXCHANGE=$MailServerIsExchange "+ `
				"POLL_EXCHANGE_ENABLED=$MailServerIsExchange "+ `
				"CERTIFICATE_NAME=ForefrontIdentityManager "+ `
				"SERVICE_ACCOUNT_NAME=$FIMServiceServiceAccount "+ `
				"SERVICE_ACCOUNT_PASSWORD=$FIMServiceServiceAccountPassword "+ `
				"SERVICE_ACCOUNT_DOMAIN=$DomainNetBIOSName "+ `
				"SERVICE_ACCOUNT_EMAIL=$FIMServiceServiceAccountEMail "+ `
				"SERVICE_MANAGER_SERVER=$Hostname "+ `
				"SYNCHRONIZATION_SERVER=$Hostname "+ `
				"SYNCHRONIZATION_SERVER_ACCOUNT=$DomainNetBIOSName\$MAFIMServiceAccount "+ `
				"SERVICEADDRESS=$ServiceFQDN "+ `
				"SHAREPOINT_URL=http://$PortalFQDN "+ `
				"REGISTRATION_PORTAL_URL=http://$PasswordRegistrationFQDN "+ `
				"FIREWALL_CONF=1 "+ `
				"SHAREPOINTUSERS_CONF=1 "+ `
				"REQUIRE_REGISTRATION_INFO=1 "+ `
				"REGISTRATION_ACCOUNT_NAME=$FIMPasswordResetServiceServiceAccount "+ `
				"REGISTRATION_ACCOUNT_DOMAIN=$DomainNetBIOSName "+ `
				"REQUIRE_RESET_INFO=1 "+ `
				"RESET_ACCOUNT_NAME=$FIMPasswordResetServiceServiceAccountPassword "+ `
				"RESET_ACCOUNT_DOMAIN=$DomainNetBIOSName "+ `
				""

if (-not ($NoPasswordReset))
{
	$Arguments = $Arguments -replace '{ADDLOCAL}', 'CommonServices,WebPortals,RegistrationPortal,ResetPortal'

	$Arguments =  $Arguments+ `
		"REGISTRATION_ACCOUNT=$DomainNetBIOSName\$FIMPasswordResetServiceServiceAccount "+ `
		"REGISTRATION_ACCOUNT_PASSWORD=$FIMPasswordResetServiceServiceAccountPassword "+ `
		"REGISTRATION_HOSTNAME=$PasswordRegistrationFQDN "+ `
		"REGISTRATION_PORT=80 "+ `
		"REGISTRATION_FIREWALL_CONFIG=1 "+ `
		"REGISTRATION_SERVERNAME=$Hostname "+ `
		"IS_REGISTRATION_EXTRANET=$IsRegistrationExtranet "+ `
		"RESET_ACCOUNT=$DomainNetBIOSName\$FIMPasswordResetServiceServiceAccount "+ `
		"RESET_ACCOUNT_PASSWORD=$FIMPasswordResetServiceServiceAccountPassword "+ `
		"RESET_HOSTNAME=$PasswordResetFQDN "+ `
		"RESET_PORT=80 "+ `
		"RESET_FIREWALL_CONF=1  "+ `
		"RESET_SERVERNAME=$Hostname "+ `
		"IS_RESET_EXTRANET=$IsResetExtranet"
}
else
{
	$Arguments = $Arguments -replace '{ADDLOCAL}', 'CommonServices,WebPortals'
}
Write-Progress -Id 1 -Activity $Activity -status "Installing"
Write-Debug "Command-line: $Arguments"

Start-Process -FilePath MSIEXEC.EXE -ArgumentList $Arguments -Wait
