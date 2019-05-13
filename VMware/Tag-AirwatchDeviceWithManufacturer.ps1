<# Tag Devices in Airwatch with Manufacturer Name

#Author: Adam Ophoff
#March 2019

  .SYNOPSIS
    This Powershell script allows you to automatically create tags in Airwatch for Devices that exist in Airwatch with their Manufacturer name
    MUST RUN AS ADMIN
  .DESCRIPTION
   This script connects to WMI and retrieves computer system information. The script will tag a device in the specified environment with the corresponding manufacturer tag.
   This facilitates device assignmnet to Smart Groups with tag filter criteria.
  .EXAMPLE
    .\Tag-AirwatchDeviceWithManufacturer.ps1 `
        -AirwatchServer "https://airwatch.company.com" `
        -AirwatchUser "Username" `
        -AirwatchPW "SecurePassword" `
        -AirwatchAPIKey "iVvHQnSXpX5elicaZPaIlQ8hCe5C/kw21K3glhZ+g/g=" `
        -AWOrganizationGroupName "myOGname" `
    .PARAMETER AirwatchServer
    Server URL for the AirWatch API Server
    .PARAMETER AirwatchUser
    An AirWatch account in the tenant is being queried.  This user must have the API role at a minimum.
    .PARAMETER AirwatchPW
    The password that is used by the user specified in the username parameter
    .PARAMETER AirwatchAPIKey
    This is the REST API key that is generated in the AirWatch Console.  You locate this key at All Settings -> Advanced -> API -> REST,
    and you will find the key in the API Key field.  If it is not there you may need override the settings and Enable API Access
    .PARAMETER AWOrganizationGroupName
    The name of the Organization Group where the device will be registered. 

#>


[CmdletBinding()]
    Param(

        [Parameter(Mandatory=$True)]
        [string]$AirwatchServer,

        [Parameter(Mandatory=$True)]
        [string]$AirwatchUser,

        [Parameter(Mandatory=$True)]
        [string]$AirwatchPW,

        [Parameter(Mandatory=$True)]
        [string]$AirwatchAPIKey,

        [Parameter(Mandatory=$True)]
        [string]$AWOrganizationGroupName

)

Function Get-OrganizationGroupID {
Write-Host("Getting Group ID from Group Name")
$endpointURL = $URL + "/system/groups/search?groupid=" + $AWorganizationGroupName
$WebGroupReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $header
$groupID = $WebGroupReturn.LocationGroups.Id.Value 
Return $groupID
}

Function Get-AirwatchDeviceID {
Write-Host("Getting Device from Serial Number")
$endpointURL = $url + "/mdm/devices?searchby=Serialnumber&id=" + $SerialNumber
$WebDeviceReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $header
$DeviceID = $WebDeviceReturn.ID.Value
Return $DeviceID
}

Function Get-AirwatchTagID {
Write-Host("Getting Tag ID from Tag Name")
$endpointURL = $url + "/mdm/tags/search?name=" + $TagName + "&organizationgroupid=" + $AirwatchGroupID
$webTagReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $header
$TagID = $webTagReturn.Tags.ID.value
Return $TagID
}

Function Get-AirwatchTagDevices {
Write-Host("Getting Devices tagged with from Tag ID")
$endpointURL = $url + "/mdm/tags/" + $AirwatchTagID + "/devices"
$webTagDevicesReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $header
$TagDevicesID = $webTagDevicesReturn.Device.DeviceID
Return $TagDevicesID
}

Function Set-AirwatchDeviceTag {
Write-Host("Setting Device with appropriate tag")
$endpointURL = $url + "/mdm/tags/" + $AirwatchTagID + "/adddevices"
$quoteCharacter = [char]34
$bulkRequestObject = "{ " + $quoteCharacter + "BulkValues" + $quoteCharacter + ":{ " + $quoteCharacter + "Value" + $quoteCharacter + ": [" + $quoteCharacter + $AirwatchDeviceID + $quoteCharacter + "]" + " }" + " }"
$webSetDeviceReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $header -Body $bulkRequestObject 
Return $webSetDeviceReturn 
}

$SystemInfo = get-wmiobject -class win32_bios
$SerialNumber = $SystemInfo.SerialNumber
if($SystemInfo.Manufacturer -like "*VMware*")
    {
    echo "VM found"
    $TagName = "VM"
    }
elseif($SystemInfo.Manufacturer -like "*Dell*")
    {
    echo "Dell found"
    $TagName = "Dell"
    }
elseif($SystemInfo.Manufacturer -like "*Microsoft*")
    {
    echo "Microsoft found"
    $TagName = "Microsoft"
    }
elseif(($SystemInfo.Manufacturer -like "*HP*") -or ($SystemInfo.Manufacturer -like "*Hewlett*"))
    {
    echo "HP found"
    $TagName = "HP"
    }

$URL = $AirwatchServer + "/API"
#Base64 Encode AW Username and Password
$combined = $AirwatchUser + ":" + $AirwatchPW
$encoding = [System.Text.Encoding]::ASCII.GetBytes($combined)
$cred = [Convert]::ToBase64String($encoding)

$header = @{
    "Authorization"  = "Basic $cred";
    "aw-tenant-code" = $AirwatchAPIKey;
    "Accept"		 = "application/json";
    "Content-Type"   = "application/json";}


#Get the Group ID for the specified OG name
$AirwatchGroupID = Get-OrganizationGroupID($AWOrganizationGroupName)

#Get the Device ID of the local machine
$AirwatchDeviceID = Get-AirwatchDeviceID($SerialNumber)

#Get the Tag ID of the tag we care about
$AirwatchTagID = Get-AirwatchTagID($TagName, $AirwatchGroupID)

#Get Device IDs that were already tagged with the tag we care about
$AirwatchTagDevices = Get-AirwatchTagDevices($AirwatchTagID)

if($AirwatchTagDevices -eq $AirwatchDeviceID)
    {
    write-host "Device is already tagged appropriately"
    }
else
    {
    write-host "no match - setting tag"
    $Result = Set-AirwatchDeviceTag($AirwatchTagID, $AirwatchDeviceID)
    }
