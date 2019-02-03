# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# January 9, 2012 | Soren Granfeldt
#	- initial version
#	  Technically unconstrained delegation works and is permitted but you 
#	  should never recommend or enforce this on your customer. Always use 
#	  constrained delegation and don’t permit protocol transition unless 
#	  you absolutely have to (which you don’t in this case).
# June 29, 2012 | Soren Granfeldt
#	- adjusted for R2 based on information from http://technet.microsoft.com/en-us/library/jj134299(v=ws.10).aspx

$Activity = "Establishing Service Principal Names (SPN's)"

Write-Progress -Id 1 -Activity $Activity -status "Importing FIAB module"
Import-Module .\FIAB-Module.psm1 -Force

Write-Progress -Id 1 -Activity $Activity -status "Importing Active Directory module"
Import-Module ActiveDirectory

[int] $ADS_UF_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION  = 16777216

# Always register both short and long (domain fqdn) for a service. This will ensure Kerberos is always available. 
$SpnFIMServiceNetBIOS = "FIMService/$ServiceNetBIOSName"
$SpnFIMServiceFQDN = "FIMService/$ServiceFQDN"

$SpnHTTPNetBIOS = "HTTP/$PortalNetBIOSName"
$SpnHTTPFQDN = "HTTP/$PortalFQDN"

$SpnHTTPPwdFQDN = "HTTP/$PasswordRegistrationFQDN"
$SpnHTTPPwdNetBIOS = "HTTP/$PasswordResetNetBIOSName"

# SPN required for the FIM Service. Allows clients the ability to locate an instance of the FIM Service.
Write-Progress -Id 1 -Activity $Activity -status "FIMService SPN's"
setspn -F -S $SpnFIMServiceNetBIOS 	-U ( '{0}\{1}' -f $DomainNetBIOSName , $FIMServiceServiceAccount )
setspn -F -S $SpnFIMServiceFQDN    	-U ( '{0}\{1}' -f $DomainNetBIOSName , $FIMServiceServiceAccount )

# the SSPR portals use IIS 7.0/7.5. IIS 7.0/7.5 has an authentication feature - 'Enable Kernel Mode Authentication'.
# With this feature the Kerberos ticket for the requested service is decrypted using Machine account (Local system) 
# of the IIS server. It no longer depends upon the application pool Identity for this purpose. The following
# assumes that the password registration and reset portals are being accessed through a custom host header.
# In this instance the SPN is required only for the IIS machine account and not for our FIM Password Service account.
Write-Progress -Id 1 -Activity $Activity -status "FIM Password Reset SPN's"
setspn -F -S $SpnHTTPPwdFQDN 		-C ( '{0}\{1}$' -f $DomainNetBIOSName, $Hostname)
setspn -F -S $SpnHTTPPwdNetBIOS 	-C ( '{0}\{1}$' -f $DomainNetBIOSName, $Hostname)

# if we want to run under an apppool, we use the spn's below (have to doublecheck though, since this setup is not confirmed)
#setspn -F -S $SpnHTTPPwdFQDN 		-U ( '{0}\{1}' -f $DomainNetBIOSName, $FIMPasswordResetServiceServiceAccount)
#setspn -F -S $SpnHTTPPwdNetBIOS 	-U ( '{0}\{1}' -f $DomainNetBIOSName, $FIMPasswordResetServiceServiceAccount)

# this is a requirement because SharePoint runs as a "farm" - even in single-server configurations. You
# have to run the site and authentication under the app pool account...and still set up your SPN's.
Write-Progress -Id 1 -Activity $Activity -status "SharePoint SPN's"
$SPAppPoolServiceAccountWithoutDomain = ($SPAppPoolServiceAccount -replace '^.+\\')
setspn -F -S $SpnHTTPNetBIOS 	-U ( '{0}\{1}' -f  $DomainNetBIOSName, $SPAppPoolServiceAccountWithoutDomain)
setspn -F -S $SpnHTTPFQDN 		-U ( '{0}\{1}' -f  $DomainNetBIOSName, $SPAppPoolServiceAccountWithoutDomain)

$FIMServiceServiceAccount, $SPAppPoolServiceAccountWithoutDomain | foreach `
{
	Write-Progress -Id 1 -Activity $Activity -status "Setting Kerberos Constrained Delegation for $_"
	$DN = Get-AdObject -LDAPFilter "(sAMAccountName=$_)" | Select -Expand DistinguishedName
	Set-AdObject "$DN" -Add @{"msDS-AllowedToDelegateTo"="$SpnFIMServiceFQDN", "$SpnFIMServiceNetBIOS" }
	$User = [ADSI] "LDAP://$DN"
	$NewValue = $User.userAccountControl.Item(0)
	$NewValue = $NewValue -bor $ADS_UF_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION
	$User.userAccountControl = $NewValue
	$User.SetInfo()
}
