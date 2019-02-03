Import-Module ActiveDirectory

New-ADOrganizationalUnit -Name BHOLD -Path "dc=r2test,dc=intern"

New-ADGroup -Name "BHOLD Application Group" -SamAccountName BHOLDAppGroup -GroupCategory Security -GroupScope Global -DisplayName "BHOLD Application Group" -Path "ou=BHOLD,dc=r2test,dc=intern" -Description "Members of this group are BHOLD Administrators"

# Clear User must change password at next logon, select User cannot change password and Password never expires,
#New-ADUser -SamAccountName "SVC-BHOLDCore" -Name "SVC-BHOLDCore" -DisplayName "BHOLD Core Service (service account)" -Path 'ou=BHOLD,dc=r2test,dc=intern' -AccountPassword (Read-Host -AsSecureString "Core Service Account Password")

#Set SPNs fo the SVC-BHOLDCore account for core fqdn alias

Add-AdGroupMember -Identity "BHOLDAppGroup" "Administrator"
Add-AdGroupMember -Identity "BHOLDAppGroup" "SVC-BHOLDCore"
Add-AdGroupMember -Identity "IIS_IUSRS" "SVC-BHOLDCore"

SeServiceLogonRight 
.\ntrights.exe +r SeServiceLogonRight  -u "R2TEST\SVC-BHOLDCore"

#HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\bhold\b1Core contains all settings i.e. NoHistory