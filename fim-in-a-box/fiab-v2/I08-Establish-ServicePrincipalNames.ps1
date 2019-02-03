# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# January 9, 2012 | Soren Granfeldt
#	- initial version
#	  Technically unconstrained delegation works and is permitted but you 
#	  should never recommend or enforce this on your customer. Always use 
#	  constrained delegation and don’t permit protocol transition unless 
#	  you absolutely have to (which you don’t in this case).

.\Common-InitializeScript.ps1

Import-Module ActiveDirectory

[int] $ADS_UF_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION  = 16777216

# Always register both short and long (domain fqdn) for a service. This will ensure Kerberos is always available. 
$SpnFIMServiceNetBIOS = "FIMService/$($Settings.FIAB.General.UnqualifiedServiceVirtualName)"
$SpnFIMServiceFQDN = "FIMService/$($Settings.FIAB.General.QualifiedServiceVirtualName)"

$SpnHTTPNetBIOS = "HTTP/$($Settings.FIAB.General.UnqualifiedPortalVirtualName)"
$SpnHTTPFQDN = "HTTP/$($Settings.FIAB.General.QualifiedPortalVirtualName)"

Write-Host "Registering FIMService Service Principal Names"
setspn -F -S $SpnFIMServiceNetBIOS -U "$DomainNetBIOSName\$($Settings.FIAB.General.ServiceAccounts.FIMService)"
setspn -F -S $SpnFIMServiceFQDN    -U "$DomainNetBIOSName\$($Settings.FIAB.General.ServiceAccounts.FIMService)"

Write-Host "Registering HTTP Service Principal Names"
setspn -F -S $SpnHTTPNetBIOS -U "$DomainNetBIOSName\$($Settings.FIAB.General.ServiceAccounts.SharePointApplicationPoolService)"
setspn -F -S $SpnHTTPFQDN -U "$DomainNetBIOSName\$($Settings.FIAB.General.ServiceAccounts.SharePointApplicationPoolService)"

$FIMServiceAccountDN = Get-AdObject -LDAPFilter "(sAMAccountName=$($Settings.FIAB.General.ServiceAccounts.FIMService))" | Select -Expand DistinguishedName
$SPAppPoolAccountDN = Get-AdObject -LDAPFilter "(sAMAccountName=$($Settings.FIAB.General.ServiceAccounts.SharePointApplicationPoolService))" | Select -Expand DistinguishedName

Write-Host "Setting Kerberos Constrained Delegation for $SPAppPoolAccountDN"
Set-AdObject "$SPAppPoolAccountDN" -Add @{"msDS-AllowedToDelegateTo"="$SpnFIMServiceFQDN", "$SpnFIMServiceNetBIOS" }
$User = [ADSI] "LDAP://$SPAppPoolAccountDN"
$NewValue = $User.userAccountControl.Item(0)
$NewValue = $NewValue -bor $ADS_UF_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION
$User.userAccountControl = $NewValue
$User.SetInfo()

Write-Host "Setting Kerberos Constrained Delegation for $FIMServiceAccountDN"
Set-AdObject "$FIMServiceAccountDN" -Add @{"msDS-AllowedToDelegateTo"="$SpnFIMServiceFQDN", "$SpnFIMServiceNetBIOS" }
$User = [ADSI] "LDAP://$FIMServiceAccountDN"
$NewValue = $User.userAccountControl.Item(0)
$NewValue = $NewValue -bor $ADS_UF_TRUSTED_TO_AUTHENTICATE_FOR_DELEGATION
$User.userAccountControl = $NewValue
$User.SetInfo()

.\Common-TerminateScript.ps1
