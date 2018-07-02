# Rename-ADUser
# A script to rename an on-premise active directory user, and then optionally change a dirsynced
# Azure AD account as well (defaulted to on).
#

$AzureAD = $true
$DirSyncServer = "<server where dirsync is run from FQDN>"
$ExchangeServer = "<primary exchange server FQDN>"

Install-Module MSOnline
Import-Module ActiveDirectory

# Get Login credentials for Domain Admin Account
$AdminCredential = Get-Credential -Message "Please enter your Domain Admin credentials"

# Get Login credentials for o365
if($AzureAD)
    {
    $365Credential = Get-Credential -Message "Please enter your Office365 Admin credentials"
    Connect-MSOLService -Credential $365Credential
    }

$OldSAM = Read-Host -Prompt "What is the user's current SAM-Account-Name (User Login Name):"
$NewFirst = Read-Host -Prompt "What is the user's (possible new?) first name?:"
$NewLast = Read-Host -Prompt "What is the user's new last name?:"
$NewSAM = Read-Host -Prompt "What is the user's new SAM-Account-Name (User Login Name):"

# Get User details
$OldUserDetails = Get-ADUser $OldSAM

Figure out the rest

$OldUPN = $OldUserDetails.UserPrincipalName
$Suffix = ($OldUPN -Split '@')[1] 
$NewUPN = $NewSAM + "@" + $Suffix

# Get Azure User details before any changes are made
if($AzureAD)
    {
    $MSOLUserBefore = get-msoluser -UserPrincipalName $OldUPN
    }

# Some cleanup, just in case
Try{
	Remove-PSSession $ExchangeSession
}
Catch{
}


##########################################################
# Change On-Prem details                                 #
#                                                        #
##########################################################

# Capitalize first characters of first name and last name
$NewFirst = $NewFirst.substring(0,1).toupper()+$NewFirst.substring(1).tolower()
$NewLast = $NewLast.substring(0,1).toupper()+$NewLast.substring(1).tolower()

# Modify Display Name with new name details but keep the same title
# Display name is in the form of "Lastname, Firstname (Title)"
$TitleBegin = $($OldUserDetails.Name).IndexOf("(")
$Title = $($OldUserDetails.Name).substring($TitleBegin)
$NewUserDisplayName = "$NewLast, $NewFirst $Title"

# Connect to exchange server
$ExchangeSession = New-PSSession -Configuration Microsoft.Exchange -ConnectionUri http://$ExchangeServer/Powershell -Authentication Kerberos -Credential $AdminCredential 
Import-PSSession $ExchangeSession

# Set search scope for entire AD forest
Set-AdServerSettings -ViewEntireForest $true

# Change User account
Set-Mailbox -Identity $OldSAM -Alias $NewSAM -DisplayName $NewUserDisplayName -SimpleDisplayName "$NewFirst $NewLast" -Name $NewUserDisplayName -UserPrincipalName $NewUPN  -SamAccountName $NewSAM 

# Pause for sync
write-host "Sleeping for 30 seconds to let things sync on the backend"
start-sleep 30

# Set correct last name on AD account (this cannot be set with the Set-Mailbox command, apparently).
Set-ADUser -Identity $NewSAM -Surname $NewLast

Remove-PSSession $ExchangeSession

# DC sync
$DomainControllers = (Get-ADForest).Domains | %{ Get-ADDomainController -Filter * -Server $_ }
$DCSession = ""
ForEach ($DC in $DomainControllers.Name) 
    {
	Write-Host "Processing for "$DC -ForegroundColor Green
		If ($DC) 
            {
            $DCSession = New-PSSession -ComputerName $DC -Credential $AdminCredential
			Invoke-Command -Session $DCSession -ScriptBlock { REPADMIN /kcc $DC }
			Invoke-Command -Session $DCSession -ScriptBlock { REPADMIN /syncall /A /e /q $DC }
            Remove-PSSession $DCSession
		    }
    }

# Get AD user details after the change
$ADUserAfter = Get-ADUser -id $NewSAM

# Display changes made to AD account
write-host "Old Active Directory Details" -ForegroundColor Red
$OldUserDetails | select-object ObjectGUID, GivenName, Surname, Name | format-Table
write-host "New Active Directory Details" -ForegroundColor Green
$ADUserAfter | select-object ObjectGUID, GivenName, Surname, Name | format-Table


##########################################################
# Change Azure AD details                                #
#                                                        #
##########################################################
if($AzureAD)
    {
    # Pause for sync
    write-host "Sleeping for 30 seconds to let things sync on the backend"
    start-sleep 30

    # Force a Azure AD dirsync
    $DirsyncSession = New-PSSession -ComputerName $DirSyncServer -Credential $AdminCredential 
    Invoke-Command -Session $DirsyncSession -ScriptBlock {Import-Module -Name 'ADSync'}
    Invoke-Command -Session $DirsyncSession -ScriptBlock {Start-ADSyncSyncCycle -PolicyType Delta}
    Remove-PSSession $DirsyncSession

    # Pause for sync
    write-host "Sleeping for 30 seconds to let things sync on the backend"
    start-sleep 30

    # Change Azure AD UPN (everything else should be sync'd via dirsync)
    Set-MsolUserPrincipalName -ObjectId $MSOLUserBefore.ObjectId -NewUserPrincipalName $NewUPN

    # Get User details
    $MSOLUserAfter = get-msoluser -UserPrincipalName $NewUPN

    # Display Changes made to Azure AD account
    write-host "Old Azure AD Details" -ForegroundColor Red
    $MSOLUserBefore | Select-Object ObjectID, FirstName, LastName, DisplayName | format-table
    write-host "New Azure AD Details" -ForegroundColor Green
    $MSOLUserAfter | Select-Object ObjectID, FirstName, LastName, DisplayName | format-table
    }
