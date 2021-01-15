Function Create-HappyfoxContact
    {
    <#
    .SYNOPSIS
    Create a contact record in Happyfox, returns true if account was created, false if it was not created or if the script experiences an error
    .EXAMPLE
    Get-HappyfoxContact -AccountURL "https://acmes.happyfox.com/" -APIKey "1234ABC" -APICode "789XYZ" -Name "Ronald McDonald" -Email "ronald@mcdonalds.com"
    .PARAMETER Name
    User's full name
    .PARAMETER Email
    User's Email
    #>
    Param
        (
        [Parameter(Mandatory=$True)]
        [string]$AccountURL,
        [Parameter(Mandatory=$True)]
        [string]$APIKey,
        [Parameter(Mandatory=$True)]
        [string]$APICode,
        [Parameter(Mandatory=$True)]
        [string]$Name,
        [Parameter(Mandatory=$True)]
        [string]$Email
        )  

    # Initialization of JSON Headers
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($APIKey):$($APICode)"))
    $Header = @{
        Authorization = "Basic $base64AuthInfo"
    }

    # Build New User information JSON
    $quoteCharacter = [char]34
    $json =  "[ {" + $quoteCharacter + "name" +  $quoteCharacter + ":" + $quoteCharacter + $Name + $quoteCharacter + "," + $quoteCharacter + "email" +  $quoteCharacter + ":" + $quoteCharacter + $Email + $quoteCharacter +  "}]"
    # Create user using the supplied name and email address
    $response = ""
    $result = ""
    $ErrorResponse = ""
    $URL = $HfApiUri + "/" + $ResponseFormat + "/users/"
    try {
        $response = Invoke-WebRequest -Uri $URL -Headers $Header -ContentType 'application/json' -Method POST -Body $json
        $result = ConvertFrom-Json -InputObject $response.Content
        return $true
    }
    catch {
        $ErrorResponse =  $_
        Return $false
    }
}

Function Get-HappyFoxAllAssets
    {
    <#
    .SYNOPSIS
    Get all of the assets in Happy Fox
    .EXAMPLE
    Get-HappyFoxAllAssets -AccountURL "https://acmes.happyfox.com/" -APIKey "1234ABC" -APICode "789XYZ"
    .PARAMETER AccountURL
    Your HappyFox URL
    .PARAMETER APIKey
    Your HappyFox API Key
    .PARAMETER APICode
    Your HappyFox API Code
    #>
    Param
        (
        [Parameter(Mandatory=$True)]
        [string]$AccountURL,
        [Parameter(Mandatory=$True)]
        [string]$APIKey,
        [Parameter(Mandatory=$True)]
        [string]$APICode
        )  

    # Initialization of JSON Headers
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($APIKey):$($APICode)"))
    $Header = @{
        Authorization = "Basic $base64AuthInfo"
    }

    $URL = "/api/1.1/json/assets/?size=100"
    $URL = $AccountURL + $URL
    
    $quoteCharacter = [char]34
    $response = ""
    $result = ""
    $ErrorResponse = ""

    try {
        $response = Invoke-WebRequest -Uri $URL -Headers $Header -ContentType 'application/json' -Method Get
        if($response.StatusCode -eq "200") {
            $result = ConvertFrom-Json -InputObject $response.Content
            return $true
            }
        else {
            return "unknown error"
        }
    }
    catch {
        $ErrorResponse =  $_
        return $ErrorResponse
    }
}

Function Delete-HappyFoxAsset
    {
    <#
    .SYNOPSIS
    Deletes an asset in Happy Fox
    .EXAMPLE
    Get-HappyFoxAllAssets -AccountURL "https://acmes.happyfox.com/" -APIKey "1234ABC" -APICode "789XYZ" -AgentID "7" -AssetID "23"
    .PARAMETER AccountURL
    Your HappyFox URL
    .PARAMETER APIKey
    Your HappyFox API Key
    .PARAMETER APICode
    Your HappyFox API Code
    .PARAMETER AgentID
    Your HappyFox Agent ID
    .PARAMETER AssetID
    The HappyFox Asset ID
    #>
    Param
        (
        [Parameter(Mandatory=$True)]
        [string]$AccountURL,
        [Parameter(Mandatory=$True)]
        [string]$APIKey,
        [Parameter(Mandatory=$True)]
        [string]$APICode,
        [Parameter(Mandatory=$True)]
        [string]$AgentID,
        [Parameter(Mandatory=$True)]
        [string]$AssetID
        )  

    # Initialization of JSON Headers
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($APIKey):$($APICode)"))
    $Header = @{
        Authorization = "Basic $base64AuthInfo"
    }

    $URL = "/api/1.1/json/asset/$AssetID/?deleted_by=$AgentID"
    $URL = $AccountURL + $URL
    
    $quoteCharacter = [char]34
    $response = ""
    $result = ""
    $ErrorResponse = ""

    try {
        $response = Invoke-WebRequest -Uri $URL -Headers $Header -ContentType 'application/json' -Method Delete
        if($response.StatusCode -eq "204") {
            return $true
        }
        else {
            return $false
        }
    }
    catch {
        $ErrorResponse =  $_
        Return $false
    }
}
