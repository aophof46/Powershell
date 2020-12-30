# Collection of powershell functions for dot sourcing

Function New-AirwatchAPIHeader {
    Param (
        [Parameter(Mandatory=$True)]
        [string]$AirwatchServer,
        [Parameter(Mandatory=$True)]
        [string]$AirwatchUser,
        [Parameter(Mandatory=$True)]
        [string]$AirwatchPW,
        [Parameter(Mandatory=$True)]
        [string]$AirwatchAPIKey
    ) 
    $URL = $AirwatchServer + "/API"
    #Base64 Encode AW Username and Password
    $combined = $AirwatchUser + ":" + $AirwatchPW
    $encoding = [System.Text.Encoding]::ASCII.GetBytes($combined)
    $cred = [Convert]::ToBase64String($encoding)

    $header = @{
        "Authorization"  = "Basic $cred";
        "aw-tenant-code" = $AirwatchAPIKey;
        "Accept"		 = "application/json";
        "Content-Type"   = "application/json";
    }
    return $header
}

Function Get-AirwatchDevices {
    Param
    (
    [Parameter(Mandatory=$True)]
    [string]$groupID
    )  
    Write-Host("Getting all Airwatch Devices")
    $endpointURL = $url + "/mdm/devices/search"
    if($groupID) {
        $endpointURL = $endpointURL + "?lgid=$groupID"
    }
    $WebDevicesReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $header
    return $WebDevicesReturn
}

Function Get-AirwatchDevice {
    param($Serial)
    Write-Host("Getting Device from Serial Number: ") -NoNewline
    $endpointURL = $url + "/mdm/devices?searchby=Serialnumber&id=" + $Serial
    $WebDeviceReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $header
    if($WebDeviceReturn) {
        write-host("Success. " + $WebDeviceReturn.ID.Value) -BackgroundColor Green
    }
    else {
        write-host("Failed.") -BackgroundColor Red
    }
    return $WebDeviceReturn
}

Function Get-OrganizationGroupID {
    param($Name)
    Write-Host("Getting Group ID from Group Name")
    $endpointURL = $URL + "/system/groups/search?groupid=" + $Name
    $WebGroupReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $header
    $groupID = $WebGroupReturn.LocationGroups.Id.Value 
    Return $groupID
}

Function Get-AirwatchTagID {
    Write-Host("Getting Tag ID from Tag Name: ") -NoNewline
    $endpointURL = $url + "/mdm/tags/search?name=" + $TagName + "&organizationgroupid=" + $AirwatchGroupID
    $webTagReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $header
    $TagID = $webTagReturn.Tags.ID.value
    if($TagID) {
        write-host("Success. $TagID") -BackgroundColor Green
    }
    else {
        write-host("Failed.") -BackgroundColor Red
    }
    Return $TagID
}

Function Get-AirwatchTags {
    param($Group)
    Write-Host("Getting All Airwatch Tags for Given Group")
    $endpointURL = $url + "/mdm/tags/search?organizationgroupid=" + $Group
    $webTagsReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $header
    return $WebTagsReturn
}
    
Function Create-AirwatchTag {
    param($TagName, $Group)
    Write-Host("Creating an Airwatch Tag $Tagname in OG ID $AirwatchGroupID")
    $quoteCharacter = [char]34
    $endpointURL = $url + "/mdm/tags/addtag"
    $CreateTagRequestObject = "{ " + $quoteCharacter + "LocationGroupID" + $quoteCharacter + ":" + $AirwatchGroupID + "," + $quoteCharacter + "TagName" + $quoteCharacter + ":" + $quoteCharacter + $Tagname + $quoteCharacter + "," + $quoteCharacter + "TagType" + $quoteCharacter + ":" + "1" + " }"
    $CreateTagReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $header -Body $CreateTagRequestObject
    return $CreateTagReturn.Value
}

Function Get-AirwatchTagDevices {
    param($TagID)
    Write-Host("Getting Devices tagged with Tag ID: $TagID : ") -NoNewline
    $endpointURL = $url + "/mdm/tags/" + $TagID + "/devices"
    $webTagDevicesReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $header
    $TagDevicesID = $webTagDevicesReturn.Device.DeviceID
    if($TagDevicesID) {
        write-host("Success.") -BackgroundColor Green
    }
    else {
        write-host("Failed.") -BackgroundColor Red
    } 
    Return $TagDevicesID
}

Function Set-AirwatchDeviceTag {
    param($TagID, $DeviceID)
    Write-Host("Setting Device with appropriate Tag ID: $TagID :") -NoNewline
    $quoteCharacter = [char]34
    $endpointURL = $url + "/mdm/tags/" + $TagID + "/adddevices"
    $bulkSetTagRequestObject = "{ " + $quoteCharacter + "BulkValues" + $quoteCharacter + ":{ " + $quoteCharacter + "Value" + $quoteCharacter + ": [" + $quoteCharacter + $DeviceID + $quoteCharacter + "]" + " }" + " }"
    $webSetDeviceReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $header -Body $bulkSetTagRequestObject
    if($webSetDeviceReturn) {
        write-host("Success.") -BackgroundColor Green
    }
    else {
        write-host("Failed.") -BackgroundColor Red
    } 
    Return $webSetDeviceReturn 
}
