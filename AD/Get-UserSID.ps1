
function Get-UserSID
    {
    <#
    .SYNOPSIS
    Function to get an active directory user's SID
    .DESCRIPTION
    queries win32_useraccount for a user in a given domain
    .EXAMPLE
    Get-UserSID -User John -Domain Contoso
    .PARAMETER User
    AD SAML username
    .PARAMETER Domain
    The AD Domain to query
    #>
    Param
        (
        [Parameter(Mandatory=$True)]
        [string]$User,
        [string]$Domain
        )    
    $error = ""
    $Result = ""
    $filter = "Name like '$User%' AND Domain = '$Domain'"
    $Result = Get-WmiObject win32_useraccount -filter $filter

    if($Result.Count -gt "1")
        {
        $error =  "Multiple user names found"
        return $error
        }
    else
        {
        return $Result.SID
        }
    }
