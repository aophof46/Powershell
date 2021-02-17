# HF API Technical reference
# https://www.happyfox.com/developers/api/1.1/

# HF Asset API documentation
# https://hf-files-oregon.s3.amazonaws.com/hdpsupport_kb_attachments/2019/12-13/1a06dc10-83ce-481b-97ac-42d65b85a1df/API_Documentation_for_creating_and_managing_assets.pdf


Function Create-HappyFoxAsset
    {
    <#
    .SYNOPSIS
    Create an asset in Happyfox, returns true if asset was created, false if it was not created or if the script experiences an error
    .EXAMPLE
    Create-HappyfoxAsset -AccountURL "https://acmes.happyfox.com" -APIKey "1234ABC" -APICode "789XYZ" -Name "Adam's iPhone" -DisplayID "9999"
    .PARAMETER AccountURL
    Your HappyFox URL
    .PARAMETER APIKey
    Your HappyFox API Key
    .PARAMETER APICode
    Your HappyFox API Code
    .PARAMETER Name
    Asset name
    .PARAMETER DisplayID
    Asset display ID
    .PARAMETER ContactID 
    Contact ID of asset user
    .PARAMETER ComputerName
    Asset Computer Name
    .PARAMETER AssetCategory
    Asset category (desktop, laptop, mobile, etc)
    .PARAMETER Description
    Asset description
    .PARAMETER SerialNumber
    Asset serial number
    .PARAMETER Location
    Asset Location  
    .PARAMETER Make
    Asset make
    .PARAMETER Model
    Asset model
    .PARAMETER Notes
    Asset notes
    .PARAMETER Status
    Asset status (active, disposed, in storage)
    .PARAMETER AgentID
    ID of agent adding this asset
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
        [string]$DisplayID,
        [int]$ContactID,
        [string]$ComputerName,
        [ValidateSet('Desktop','Docking Station','Laptop','Mobile','Monitor','Printer','Scanner','Tablet')]
        [string]$AssetCategory,
        [string]$Description,
        [string]$SerialNumber,
        [string]$Location,
        [string]$Make,
        [string]$Model,
        [string]$Notes,
        [ValidateSet('Active','Disposed','In Storage')]
        [string]$Status,
        [Parameter(Mandatory=$false)]
        [int]$AgentID = 9
        )  

    # Initialization of JSON Headers
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($APIKey):$($APICode)"))
    $Header = @{
        Authorization = "Basic $base64AuthInfo"
    }

    Switch($AssetCategory) {
        "Desktop" {$CategoryVar = 5}
        "Docking Station" {$CategoryVar = 11}
        "Laptop" {$CategoryVar = 4}
        "Mobile" {$CategoryVar = 6}
        "Monitor" {$CategoryVar = 10}
        "Printer" {$CategoryVar = 8}
        "Scanner" {$CategoryVar = 9}
        "Tablet" {$CategoryVar = 7}
    }

    Switch($Status) {
        "Active" {$StatusVar = 1}
        "Disposed" {$StatusVar = 3}
        "In Storage" {$StatusVar = 2}
    }

    # Request Data Fields
    $AssetObj = New-Object System.Object
    $AssetObj | Add-Member -MemberType NoteProperty -Name 'name' -Value $Name
    $AssetObj | Add-Member -MemberType NoteProperty -Name 'display_id' -Value $DisplayID
    $assetObj | Add-Member -MemberType NoteProperty -Name 'created_by' -Value $AgentID
    if($ContactID) { $assetObj | Add-Member -MemberType NoteProperty -Name 'contact_ids' -Value "[$ContactID]" }

    # Custom Attribute Data Fields
    # if I had more time, i'd write a fancy function to look up ID by name rather than this static list...
    # name                 id
    # ----                 --
    # Computer Name         3
    # Asset Category        1
    # Description           2
    # Serial Number         4
    # End of Warranty Date  5
    # Phone Number          6
    # Location              7
    # Make                  8
    # Model                 9
    # Notes                11
    # Status               12
    # Disposition Date     13
    $AssetCustomAttributeObj = New-Object System.Object
    if($ComputerName) { $AssetCustomAttributeObj | Add-Member -MemberType NoteProperty -Name 3 -Value $ComputerName }
    if($AssetCategory) { $AssetCustomAttributeObj | Add-Member -MemberType NoteProperty -Name 1 -Value $CategoryVar }
    if($Description) { $AssetCustomAttributeObj | Add-Member -MemberType NoteProperty -Name 2 -Value $Description}
    if($SerialNumber) { $AssetCustomAttributeObj | Add-Member -MemberType NoteProperty -Name 4 -Value $SerialNumber }
    if($Location) { $AssetCustomAttributeObj | Add-Member -MemberType NoteProperty -Name 7 -Value $Location }
    if($Make) { $AssetCustomAttributeObj| Add-Member -MemberType NoteProperty -Name 8 -Value $Make }
    if($Model) { $AssetCustomAttributeObj| Add-Member -MemberType NoteProperty -Name 9 -Value $Model}
    if($Notes) { $AssetCustomAttributeObj | Add-Member -MemberType NoteProperty -Name 11 -Value $Notes }
    if($Status) { $AssetCustomAttributeObj | Add-Member -MemberType NoteProperty -Name 12 -Value $StatusVar }

    # Contacts must be in an array form in order to work
    $Contacts = @()
    $Contacts += $ContactID

    $jsonDoc = [pscustomobject]@{
        name = $Name
        display_id = $DisplayID
        created_by = $AgentID
        contact_ids = $Contacts 
        custom_fields = $AssetCustomAttributeObj 
    }
    $json = $jsonDoc | Convertto-json

    # Create asset
    $response = ""
    $ResponseFormat = "json"
    $result = ""
    $ErrorResponse = ""
    $URL = $AccountURL + "/api/1.1/json/assets/"
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


Function Update-HappyFoxAsset
    {
    <#
    .SYNOPSIS
    Update an asset in Happyfox, returns true if asset was created, false if it was not created or if the script experiences an error
    .EXAMPLE
    Update-HappyfoxAsset -AccountURL "https://acmes.happyfox.com" -APIKey "1234ABC" -APICode "789XYZ" -HappyFoxID 32 -Name "Adam's iPhone" -DisplayID "9999"
    .PARAMETER AccountURL
    Your HappyFox URL
    .PARAMETER APIKey
    Your HappyFox API Key
    .PARAMETER APICode
    Your HappyFox API Code
    .PARAMETER HappyFoxID
    Asset ID
    .PARAMETER Name
    Asset name
    .PARAMETER DisplayID
    Asset display ID
    .PARAMETER ContactID 
    Contact ID of asset user
    .PARAMETER ComputerName
    Asset Computer Name
    .PARAMETER AssetCategory
    Asset category (desktop, laptop, mobile, etc)
    .PARAMETER Description
    Asset description
    .PARAMETER SerialNumber
    Asset serial number
    .PARAMETER Location
    Asset Location  
    .PARAMETER Make
    Asset make
    .PARAMETER Model
    Asset model
    .PARAMETER Notes
    Asset notes
    .PARAMETER Status
    Asset status (active, disposed, in storage)
    .PARAMETER AgentID
    ID of agent adding this asset
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
        [int]$HappyFoxID,
        [Parameter(Mandatory=$True)]
        [string]$Name,
        [string]$DisplayID,
        [int]$ContactID,
        [string]$ComputerName,
        [ValidateSet('Desktop','Docking Station','Laptop','Mobile','Monitor','Printer','Scanner','Tablet')]
        [string]$AssetCategory,
        [string]$Description,
        [string]$SerialNumber,
        [string]$Location,
        [string]$Make,
        [string]$Model,
        [string]$Notes,
        [ValidateSet('Active','Disposed','In Storage')]
        [string]$Status,
        [Parameter(Mandatory=$false)]
        [int]$AgentID = 9
        )  

    # Initialization of JSON Headers
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($APIKey):$($APICode)"))
    $Header = @{
        Authorization = "Basic $base64AuthInfo"
    }

    Switch($AssetCategory) {
        "Desktop" {$CategoryVar = 5}
        "Docking Station" {$CategoryVar = 11}
        "Laptop" {$CategoryVar = 4}
        "Mobile" {$CategoryVar = 6}
        "Monitor" {$CategoryVar = 10}
        "Printer" {$CategoryVar = 8}
        "Scanner" {$CategoryVar = 9}
        "Tablet" {$CategoryVar = 7}
    }

    Switch($Status) {
        "Active" {$StatusVar = 1}
        "Disposed" {$StatusVar = 3}
        "In Storage" {$StatusVar = 2}
    }

    # Request Data Fields
    $AssetObj = New-Object System.Object
    $AssetObj | Add-Member -MemberType NoteProperty -Name 'name' -Value $Name
    $AssetObj | Add-Member -MemberType NoteProperty -Name 'display_id' -Value $DisplayID
    $assetObj | Add-Member -MemberType NoteProperty -Name 'created_by' -Value $AgentID
    if($ContactID) { $assetObj | Add-Member -MemberType NoteProperty -Name 'contact_ids' -Value "[$ContactID]" }

    # Custom Attribute Data Fields
    # if I had more time, i'd write a fancy function to look up ID by name rather than this static list...
    # name                 id
    # ----                 --
    # Computer Name         3
    # Asset Category        1
    # Description           2
    # Serial Number         4
    # End of Warranty Date  5
    # Phone Number          6
    # Location              7
    # Make                  8
    # Model                 9
    # Notes                11
    # Status               12
    # Disposition Date     13
    $AssetCustomAttributeObj = New-Object System.Object
    if($ComputerName) { $AssetCustomAttributeObj | Add-Member -MemberType NoteProperty -Name 3 -Value $ComputerName }
    if($AssetCategory) { $AssetCustomAttributeObj | Add-Member -MemberType NoteProperty -Name 1 -Value $CategoryVar }
    if($Description) { $AssetCustomAttributeObj | Add-Member -MemberType NoteProperty -Name 2 -Value $Description}
    if($SerialNumber) { $AssetCustomAttributeObj | Add-Member -MemberType NoteProperty -Name 4 -Value $SerialNumber }
    if($Location) { $AssetCustomAttributeObj | Add-Member -MemberType NoteProperty -Name 7 -Value $Location }
    if($Make) { $AssetCustomAttributeObj| Add-Member -MemberType NoteProperty -Name 8 -Value $Make }
    if($Model) { $AssetCustomAttributeObj| Add-Member -MemberType NoteProperty -Name 9 -Value $Model}
    if($Notes) { $AssetCustomAttributeObj | Add-Member -MemberType NoteProperty -Name 11 -Value $Notes }
    if($Status) { $AssetCustomAttributeObj | Add-Member -MemberType NoteProperty -Name 12 -Value $StatusVar }

    # Contacts must be in an array form in order to work
    $Contacts = @()
    $Contacts += $ContactID

    $jsonDoc = [pscustomobject]@{
        name = $Name
        display_id = $DisplayID
        updated_by = $AgentID
        contact_ids = $Contacts 
        custom_fields = $AssetCustomAttributeObj 
    }
    $json = $jsonDoc | Convertto-json

    # Create asset
    $response = ""
    $ResponseFormat = "json"
    $result = ""
    $ErrorResponse = ""
    $URL = $AccountURL + "/api/1.1/json/asset/$HappyFoxID/"

    if(Invoke-WebRequest -Uri $URL -Headers $Header -ContentType 'application/json' -Method Get) {

    }
    try {
        $response = Invoke-WebRequest -Uri $URL -Headers $Header -ContentType 'application/json' -Method PUT -Body $json
        $result = ConvertFrom-Json -InputObject $response.Content
        return $true
    }
    catch {
        $ErrorResponse =  $_
        Return $false
    }
}



Function Create-HappyfoxContact
    {
    <#
    .SYNOPSIS
    Create a contact record in Happyfox, returns true if account was created, false if it was not created or if the script experiences an error
    .EXAMPLE
    Create-HappyfoxContact -AccountURL "https://acmes.happyfox.com" -APIKey "1234ABC" -APICode "789XYZ" -Name "Ronald McDonald" -Email "ronald@mcdonalds.com"
    .PARAMETER AccountURL
    Your HappyFox URL
    .PARAMETER APIKey
    Your HappyFox API Key
    .PARAMETER APICode
    Your HappyFox API Code
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
    $ResponseFormat = "json"
    $result = ""
    $ErrorResponse = ""
    $URL = $AccountURL + "/api/1.1/json/users/"
    try {
        $response = Invoke-WebRequest -Uri $URL -Headers $Header -ContentType 'application/json' -Method POST -Body $json
        $result = ConvertFrom-Json -InputObject $response.Content
        return $result
    }
    catch {
        $ErrorResponse =  $_
        Return $ErrorResponse
    }
}
Function Get-HappyFoxAllAssets
    {
    <#
    .SYNOPSIS
    Get all of the assets in Happy Fox
    .EXAMPLE
    Get-HappyFoxAllAssets -AccountURL "https://acmes.happyfox.com" -APIKey "1234ABC" -APICode "789XYZ"
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

    $quoteCharacter = [char]34
    $response = ""
    $ErrorResponse = ""

    #
    # last_index = total number of assets
    # start_index = start index on this page
    # end_index = end index on this page

    $result = @()
    $assets = @()
    [INT]$LastIndex = "0"
    [INT]$EndEndex = "0"
    [INT]$Page = "1"
    [INT]$AssetsPerPage = "50" #Max size is 50

    $URLString = "/api/1.1/json/assets/?size=$AssetsPerPage"
    $URLString = $AccountURL + $URLString 

    try {
        do {
            $URL = $URLString + "&page=$page"
            $response = Invoke-WebRequest -Uri $URL -Headers $Header -ContentType 'application/json' -Method Get
            $result = $(ConvertFrom-Json -InputObject $response.Content)
            $assets += $result.data
            $page = $page + "1"
            $LastIndex = $result.page_info.last_index
            $EndIndex = $result.page_info.end_index
            #write-host "Page # $page"
            #write-host "Last Index $LastIndex"
            #write-host "End Endex $EndIndex"

        }
        until($LastIndex -eq $EndIndex)
        return $assets
    }
    catch {
        $ErrorResponse =  $_
        return $ErrorResponse
    }
}

Function Get-HappyFoxUser
    {
    <#
    .SYNOPSIS
    Gets HF user by email, if no email is specified, gets all of the users in Happy Fox
    .EXAMPLE
    Get-HappyFoxUser -AccountURL "https://acmes.happyfox.com" -APIKey "1234ABC" -APICode "789XYZ"
    Get-HappyFoxUser -AccountURL "https://acmes.happyfox.com" -APIKey "1234ABC" -APICode "789XYZ" -Email "adam@email.com"
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
        [string]$APICode,
        [string]$Email
        )  

    # Initialization of JSON Headers
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($APIKey):$($APICode)"))
    $Header = @{
        Authorization = "Basic $base64AuthInfo"
    }

    $quoteCharacter = [char]34
    $response = ""
    $ErrorResponse = ""

    $result = @()
    $assets = @()
    [INT]$LastIndex = "0"
    [INT]$EndEndex = "0"
    [INT]$Page = "1"
    [INT]$StaffPerPage = "50" #Max size is 50



    try {
        
        if($Email) {
            $URL = $AccountURL + "/api/1.1/json/user/" + "$Email/"
            $response = Invoke-WebRequest -Uri $URL -Headers $Header -ContentType 'application/json' -Method Get
            $result = $(ConvertFrom-Json -InputObject $response.Content)
            return $result
        }
        else {
            $URLString = $AccountURL + "/api/1.1/json/users/?size=$StaffPerPage"
            do {
                $URL = $URLString + "&page=$page"
                $response = Invoke-WebRequest -Uri $URL -Headers $Header -ContentType 'application/json' -Method Get
                $Content = $(ConvertFrom-Json -InputObject $response.Content)
                $result += $Content.data
                $page = $page + "1"
                $LastIndex = $Content.page_info.last_index
                $EndIndex = $Content.page_info.end_index
                #write-host "Page # $page"
                #write-host "Last Index $LastIndex"
                #write-host "End Endex $EndIndex"
    
            }
            until($LastIndex -eq $EndIndex)
            return $result
        }
    }
    catch {
        $ErrorResponse =  $_
        return $ErrorResponse
    }
}

Function Get-HappyFoxStaff
    {
    <#
    .SYNOPSIS
    Gets HF staff member by email, if no email is specified, gets all of the staff members in Happy Fox
    .EXAMPLE
    Get-HappyFoxAllStaff -AccountURL "https://acmes.happyfox.com" -APIKey "1234ABC" -APICode "789XYZ"
    Get-HappyFoxAllStaff -AccountURL "https://acmes.happyfox.com" -APIKey "1234ABC" -APICode "789XYZ" -Email "adam@email.com"
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
        [string]$APICode,
        [string]$Email
        )  

    # Initialization of JSON Headers
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($APIKey):$($APICode)"))
    $Header = @{
        Authorization = "Basic $base64AuthInfo"
    }

    $quoteCharacter = [char]34
    $response = ""
    $ErrorResponse = ""

    $result = @()
    $assets = @()


    $URLString = "/api/1.1/json/staff/"
    if($Email) {
        $URLString = $URLString + "$Email/"
    }
    $URLString = $AccountURL + $URLString 

    try {
        $response = Invoke-WebRequest -Uri $URLString -Headers $Header -ContentType 'application/json' -Method Get
        $result = $(ConvertFrom-Json -InputObject $response.Content)
        return $result
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
