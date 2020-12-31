Function Get-DomainFromDN {
    <#
    .SYNOPSIS
    Function to get the Domain from a users distinguished name
    .EXAMPLE
    Get-DomainFromDN -user adam
    .PARAMETER user
    AD Distinguished name
    #>
    Param
        (
        [Parameter(Mandatory=$True)]
        [string]$UserDN,
        [bool]$Output = $false
        )  

    if(!(get-module -list activedirectory)) {
            write-host "ActiveDirectory module not found" -BackgroundColor Red
            break
        }

    if($Output) {
        $ErrorActionPreference = "Continue"
        $WarningPreference = "Continue"
        $InformationPreference = "Continue"   
    }
    else {
        $ErrorActionPreference = "SilentlyContinue"
        $WarningPreference = "SilentlyContinue"
        $InformationPreference = "SilentlyContinue"  
    }

    $DN = $UserDN
    $pattern = '(?i)DC=\w{1,}?\b'
    $Domain = ([RegEx]::Matches($DN, $pattern) | ForEach-Object { $_.Value }) -join ',' 

    return $Domain
}

Function Get-GlobalCatalog {
    $GlobalCatalog = $(Get-ADForest).GlobalCatalogs
    $GC = $GlobalCatalog[0] + ":3268"
    Return $GC
}

function Test-ADCredentials {
    <#
    .SYNOPSIS
        Takes a PSCredential object and validates it against the domain (or local machine, or ADAM instance).

    .PARAMETER cred
        A PScredential object with the username/password you wish to test. Typically this is generated using the Get-Credential cmdlet. Accepts pipeline input.

    .PARAMETER context
        An optional parameter specifying what type of credential this is. Possible values are 'Domain','Machine',and 'ApplicationDirectory.' The default is 'Domain.'

    .OUTPUTS
        A boolean, indicating whether the credentials were successfully validated.

    #>
    param(
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [System.Management.Automation.PSCredential]$credential,
        [parameter()][validateset('Domain','Machine','ApplicationDirectory')]
        [string]$context = 'Domain'
    )
    begin {
        Add-Type -assemblyname system.DirectoryServices.accountmanagement
        $DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::$context) 
    }
    process {
        $DS.ValidateCredentials($credential.UserName, $credential.GetNetworkCredential().password)
    }
}

Function Get-ADForestInfo {
    $Forest = Get-ADForest
    $Domains = $Forest.Domains
    $DomainInfo = @()

    foreach($Domain in $Domains) {
        $obj = $Null
        $obj = New-Object System.Object
        $obj | Add-Member -Type NoteProperty -Name Domain -value $Domain
        $obj | Add-Member -Type NoteProperty -Name Server -value (Get-ADDomain $Domain).PDCEmulator
        $obj | Add-Member -Type NoteProperty -Name Netbios -value (Get-ADDomain $Domain).NetBIOSName
        $obj | Add-Member -Type NoteProperty -Name DN -value (Get-ADDomain $Domain).DistinguishedName
        $obj | Add-Member -Type NoteProperty -Name GraveyardOU -value (Get-ADOrganizationalUnit -Server $Domain -Filter {Name -like "Graveyard"}).DistinguishedName
        $obj | Add-Member -Type NoteProperty -Name NewAccountsOU -value (Get-ADOrganizationalUnit -Server $Domain -Filter {Name -like "New Accounts"}).DistinguishedName
        $obj | Add-Member -Type NoteProperty -Name SharedMbxOU -value (Get-ADOrganizationalUnit -Server $Domain -Filter {(Name -like "Shared Mailboxes")}).DistinguishedName
        $DomainInfo += $obj
    }
    Return $DomainInfo
}

Function Find-ADUser {
    <#
    .SYNOPSIS
    Function to search all domains for a matching AD account, retrieve a match or a list of matches for selection of one name, and return it.
    .EXAMPLE
    Find-ADUser -user adam
    .PARAMETER user
    AD SAML username
    #>
    Param (
        [Parameter(Mandatory=$True)]
        [string]$User,
        [bool]$Output = $false
    )  

    if(!(get-module -list activedirectory)) {
            write-host "ActiveDirectory module not found" -BackgroundColor Red
            break
    }

    if($Output) {
        $ErrorActionPreference = "Continue"
        $WarningPreference = "Continue"
        $InformationPreference = "Continue"   
    }
    else {
        $ErrorActionPreference = "SilentlyContinue"
        $WarningPreference = "SilentlyContinue"
        $InformationPreference = "SilentlyContinue"  
    }

    $GlobalCatalog = $(Get-ADForest).GlobalCatalogs
    $GC = $GlobalCatalog[0] + ":3268"
        
    $UserListArray = @()

    $Domains = $(Get-ADForest).Domains
    $WildcardName = "*$User*"
    
    # First search given names for supplied first name with wildcards.  I'll sometimes supply the samaccountname, so if
    # this search turns nothing up, then do another search against the AD identity with no wildcards.
    $userlistarray += Get-Aduser -server $GC -Properties * -Filter {(GivenName -like $WildcardName)} 
    if(!($userlistarray)) {
        $userlistarray += Get-Aduser -Identity $User -server $GC -Properties *
    }
 
    # If just one match, return it.  Otherwise let the user pick.
    if($UserListArray.count -eq "1") {
        $value = $UserListArray
        return $value
    }
    elseif($UserListArray.count -eq "0") {
        $value = ""
        return $value
    }
    else {
        # Keep presenting the user with choices until just one name is chosen
        $Choices = "2"
        While($Choices -gt "1") {
            $UserChoice = $UserListArray | select-object name, samaccountname, userprincipalname | sort-object name | Out-gridview -PassThru -Title "Multiple users found.  Select one."
            $Choices = $Userchoice.Count
        }
        $value = $UserListArray | where-object {$_.userprincipalname -eq $UserChoice.userprincipalname }
        return $value
    }
}


Function Find-ADComputer {
    <#
    .SYNOPSIS
    Function to search all domains for a matching AD computer account, retrieve a match or a list of matches for selection of one name, and return it.
    .EXAMPLE
    Find-ADComputer -ComputerName MYPC-WIN10
    .PARAMETER ComputerName
    Computer name
    #>
    Param (
        [Parameter(Mandatory=$True)]
        [string]$ComputerName,
        [bool]$Output = $false
    ) 

    if(!(get-module -list activedirectory)) {
        write-host "ActiveDirectory module not found" -BackgroundColor Red
        break
    }

    $Domains = $(Get-ADForest).Domains
    $GlobalCatalogs = $(Get-ADForest).GlobalCatalogs

    # Get all matches from all global catalog 
    TRY {
		$computerlistarray += Get-ADComputer -Identity $ComputerName -server "$($GlobalCatalogs[0]):3268" -Properties *
    }
	  Catch {
		$computerlistarray += Get-AdComputer -server "$($GlobalCatalogs[0]):3268" -Properties * -LDAPFilter "(name=*$ComputerName*)"
    }

    # If just one match, return it.  Otherwise let the user pick.
    if($computerlistarray.count -eq "1") {
        $value = $computerlistarray
        return $value
    }
    elseif($computerlistarray.count -eq "0") {
        $value = ""
        return $value
    }
    else {
        # Keep presenting the user with choices until just one name is chosen
        $Choices = "2"
        While($Choices -gt "1") {
            $ComputerChoice = $computerlistarray | select-object name, PasswordLastSet, DistinguishedName| Out-gridview -PassThru -Title "Multiple computers found.  Select one."
            $Choices = $ComputerChoice.Count
        }
        $value = $computerlistarray  | where-object {$_.DistinguishedName -eq $ComputerChoice.DistinguishedName }
        return $value
    }
}

function Copy-ADUserGroups {
    <#
    .SYNOPSIS
    Function to add one AD user's groups to another AD User, while not copying blacklisted groups
    .DESCRIPTION
    Function to add one AD user's groups to another AD User, while not copying blacklisted groups
    .EXAMPLE
    Copy-ADUserGroups -target Jeff -source Sue
    .PARAMETER Target
    AD User object
    .PARAMETER Source
    AD User object
    #>
    Param (
        [Parameter(Mandatory=$True)]
        $Target,
        [Parameter(Mandatory=$True)]
        $Source,
        [bool]$Output = $false
    )  

    $BlackListGroups = @()
    $BlackListArray = @()
    $BlackListArray = "Groups", "You", "Dont", "Want", "Copied"

    $Domains = $(Get-ADForest).Domains

    foreach($Domain in $Domains) {
        foreach($Name in $BlackListArray) {
            $BlackListGroups += Get-ADGroup -Server $Domain -Filter "name -like '$Name*'"
        }
    }

    $ADTargetDomain = $Target.CanonicalName.split("/")[0]
    $ADSourceDomain = $Source.CanonicalName.split("/")[0]

    #$ADTargetNetbios = (Get-ADDomain (($Target.DistinguishedName.Split(",") | ? {$_ -like "DC=*"}) -join ",")).NetBIOSName
    #$ADSourceNetbios = (Get-ADDomain (($Source.DistinguishedName.Split(",") | ? {$_ -like "DC=*"}) -join ",")).NetBIOSName

    $ADTargetNetbios = (Get-ADDomain $ADTargetDomain).NetBIOSName
    $ADSourceNetbios = (Get-ADDomain $ADSourceDomain).NetBIOSName

    $AllGroups = Get-ADPrincipalGroupMembership $Source.SamAccountName -server $ADSourceDomain | Where-Object {$BlackListGroups.Name -NotContains $_.Name} | sort-object name 
   
    if($Output) {
        write-host "Target User:    " $Target.SamAccountName
        write-host "Target Domain:  " $ADTargetDomain
        write-host "Target Netbios: " $ADTargetNetbios

        write-host "Source User:    " $Source.SamAccountName
        write-host "Source Domain:  " $ADSourceDomain
        write-host "Source Netbios: " $ADSourceNetbios

	    Write-Host "Below are the names of the groups that $userlike belongs to (excluding blacklisted groups).  These groups will be added to the new user."	
        $AllGroups | Select-Object -ExpandProperty name
    }

	ForEach($group in $AllGroups) {
		#Find group's domain from DN
		$AddGroupDomain = ((($group -replace "(.*?)DC=(.*)",'$2') -replace "DC=","") -replace ",",".")
		#Find group's GUID
		$AddGroupGUID = $group.objectGUID
		#Add member to group on proper domain's DC
		Set-ADGroup -Server $AddGroupDomain -Identity $AddGroupGUID -Add @{member=$($Target.DistinguishedName)}
    }
}
