# FIM-in-a-Box Installation and configuration scripts
# Copyright 2010-2012, Microsoft Corporation
#
# June 28, 2012 | Soren Granfeldt
#	- initial version

$Activity = "Configuring Default Site"

Write-Progress -Id 1 -Activity $Activity -status "Importing FIAB module"
Import-Module .\FIAB-Module.psm1 -Force

Write-Progress -Id 1 -Activity $Activity -status "Loading SharePoint snap-ins"
if (-not (Get-PsSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue)) { Add-PsSnapin Microsoft.SharePoint.PowerShell }

Write-Progress -Id 1 -Activity $Activity -status "Detecting site owner information from Active Directory"
$PrimaryOwner = ([adsisearcher] "sAMAccountName=$UsernameWithoutDomain").FindOne().GetDirectoryEntry()
$PrimaryOwnerMail = "$($PrimaryOwner.mail)"
$PrimaryOwnerDisplayName = "$($PrimaryOwner.displayName)"
$PrimaryOwnerLogin = $UsernameWithDomain
if (!$PrimaryOwnerDisplayName) { throw "Primary owner $UsernameWithoutDomain must have a display name" } else { Write-Debug "SP Site Collection owner (mail): $PrimaryOwnerMail" }
if (!$PrimaryOwnerMail) { throw "Primary owner $UsernameWithoutDomain must have a mail address" } else { Write-Debug "SP Site Collection owner (displayName): $PrimaryOwnerDisplayName" }

if ($SPSiteCollectionSecondaryOwner)
{
	Write-Progress -Id 1 -Activity $Activity -status "Detecting secondary site owner information from Active Directory"
	$SecondaryOwner = ([adsisearcher] "sAMAccountName=$SPSiteCollectionSecondaryOwner").FindOne().GetDirectoryEntry()
	$SecondaryOwnerMail = "$($SecondaryOwner.mail)"
	$SecondaryOwnerDisplayName = "$($SecondaryOwner.displayName)"
	$SecondaryOwnerLogin = "{0}\{1}" -F $DomainNetBIOSName, $SPSiteCollectionSecondaryOwner
	if (!$SecondaryOwnerDisplayName) { throw "Secondary owner $SPSiteCollectionSecondaryOwner must have a display name" } else { Write-Debug "SP Site Collection secondary owner (mail): $SecondaryOwnerMail" }
	if (!$SecondaryOwnerMail) { throw "Secondary owner $SPSiteCollectionSecondaryOwner must have a mail address" } else { Write-Debug "SP Site Collection secondary owner (displayName): $SecondaryOwnerDisplayName" }
}

# this user has to be a Sharepoint Managed Account
Write-Progress -Id 1 -Activity $Activity -status "Creating Managed Account $SPAppPoolServiceAccount"
$SecurePassword = ConvertTo-SecureString $SPAppPoolServiceAccountPassword -AsPlainText -Force
$Creds = New-Object System.Management.Automation.PSCredential ($SPAppPoolServiceAccount, $SecurePassword) 
New-SPManagedAccount -Credential $Creds -ErrorAction SilentlyContinue

Write-Progress -Id 1 -Activity $Activity -status "Creating Web Application"
$params = @{
	Name = $SPWebApplicationName 
	Port = $SPWebApplicationPort 
	URL = "http://{0}" -F $DnsHostname # later, we'll change this and add alternate url's
	ApplicationPool = $WebApplicationAppPool 
	ApplicationPoolAccount = (Get-SPManagedAccount $SPAppPoolServiceAccount) 
	DatabaseName = $WebApplicationDatabaseName 
	DatabaseServer = $SQLServerWithInstance 
	AuthenticationMethod = $SPAuthentication
}
New-SPWebApplication @params

$SPUrl = "http://{0}" -F $DnsHostname
if ( !(Get-SPSite -WebApplication $SPUrl -ErrorAction SilentlyContinue) )
{ 
	Write-Progress -Id 1 -Activity $Activity -status "Creating Sharepoint Site Collection"
	$params = @{
		Language = $SPSiteCollectionLanguage 
		Name = $SPSiteCollectionName
		OwnerAlias = $SPSiteCollectionOwner
		#OwnerEmail = $PrimaryOwnerMail # there is a bug with local email domains not being accepted. So we'll skip setting the mail address and just let SP pick this up from AD
		Template = $SPSiteCollectionTemplate 
		URL = "http://{0}" -F $DnsHostname  # later, we'll change this and add alternate url's
	}
	if ($SPSiteCollectionSecondaryOwner)
	{
		$params.Add("SecondaryOwnerAlias", $SecondaryOwnerLogin)
		#$params.Add("SecondaryEmail", $SecondaryOwnerMail) # there is a bug with local email domains not being accepted. So we'll skip setting the mail address and just let SP pick this up from AD
	}
	$params
	New-SPSite @params
}
else
{
	Write-Warning "Site $SPUrl already exists"
}

# Names of the default Members and Viewers groups. You shouldn’t have to change these unless you’re using a default language other than English
$MembersGroup = "$SPWebApplicationName Members"
Write-Debug "SP Members Group: $MembersGroup"
$ViewersGroup = "Viewers"
Write-Debug "SP Viewers Group: $ViewersGroup"

# In the user interface, after creating a site collection, the default groups are configured
# automatically. This is not true of the New-SPSite cmdlet, so we have to create the default groups (Visitor, Members, and Owners)
Write-Progress -Id 1 -Activity $Activity -status "Updating default users and groups on $SPUrl"
$SPWeb = Get-SPWeb $SPUrl -ErrorAction SilentlyContinue
if ($SPWeb)
{
	$SPWeb.CreateDefaultAssociatedGroups($PrimaryOwnerLogin, $SecondaryOwnerLogin, "")

	# In the user interface, the primary and secondary site collection administrators
	# are displayed with their friendly display names as looked up in Active Directory,
	# but with PowerShell the users are added to the site collection with their
	# display name set to their user name. These lines of code update the display names.
	$PrimaryAdmin = Get-SPUser $PrimaryOwnerLogin -Web $SPUrl -ErrorAction SilentlyContinue
	if ($PrimaryAdmin)
	{
		$PrimaryAdmin.Name = $PrimaryOwnerDisplayname
		$PrimaryAdmin.Update()
	}

	$SecondaryAdmin = Get-SPUser $SecondaryOwnerLogin -Web $SPUrl -ErrorAction SilentlyContinue
	if ($SecondaryAdmin)
	{
		$SecondaryAdmin.Name = $SecondaryOwnerDisplayname
		$SecondaryAdmin.Update()
	}

	# finish by disposing of the SPWeb object to be a good PowerShell citizen
	$SPWeb.Dispose()
}
else
{
	Write-Error "Cannot get SPWeb $SPUrl"
}

Write-Progress -Id 1 -Activity $Activity -status "Setting alternate URL's on $SPUrl"
# internal url's
New-SPAlternateURL -WebApplication "http://$DnsHostname" -Url "http://localhost" -Zone Default -Internal 
New-SPAlternateURL -WebApplication "http://$DnsHostname" -Url "http://$Hostname" -Zone Internet -Internal
New-SPAlternateURL -WebApplication "http://$DnsHostname" -Url "http://$PortalNetBIOSName" -Zone Internet -Internal

# public url's (fqdn aliases)
New-SPAlternateURL -WebApplication "http://$DnsHostname" -Url "http://$PortalFQDN" -Zone Default # change the default access url
New-SPAlternateURL -WebApplication "http://$PortalFQDN"  -Url "http://$DnsHostname" -Zone Intranet # add the original fqdn of the server (after changing the default access url)
