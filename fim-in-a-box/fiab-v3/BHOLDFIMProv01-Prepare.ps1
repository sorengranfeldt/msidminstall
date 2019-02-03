New-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\bhold\b1Core" -Name "DomainName" -Value "R2TEST" -PropertyType "String"

New-ItemProperty "HKLM:\SOFTWARE\Wow6432Node\bhold\b1Core" -Name "BFSSManagedAttributeRoles" -Value "jobtitle,JT-;securityclass,SC-" -PropertyType "String"

BFSSManageAttributeRoles
BFSSManagedAttributeRoles