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
    .\Airwatch-SetDeviceTags.ps1 `
        -AirwatchServer "https://airwatch.company.com" `
        -AirwatchUser "Username" `
        -AirwatchPW "SecurePassword" `
        -AirwatchAPIKey "xxxxapikeyxxxx" `
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


$version = 2


Function Get-OrganizationGroupID {
    param($Name)
    Write-Host("Getting Group ID from Group Name: ") -NoNewline
    $endpointURL = $URL + "/system/groups/search?groupid=" + $Name
    $WebGroupReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $header
    $groupID = $WebGroupReturn.LocationGroups.Id.Value 
    if($groupID) {
        write-host("Success.  $groupID") -BackgroundColor Green
    }
    else {
        write-host("Failed.") -BackgroundColor Red
    }
    Return $groupID
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

Function Get-AirwatchDevices {
    Write-Host("Getting all Airwatch Devices: ") -NoNewline
    $endpointURL = $url + "/mdm/devices/search"
    $WebDevicesReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $header
    if($WebDevicesReturn) {
        write-host("Success.") -BackgroundColor Green
    }
    else {
        write-host("Failed.") -BackgroundColor Red
    }
    return $WebDevicesReturn
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
    Write-Host("Getting All Airwatch Tags for Given Group: ") -NoNewline
    $endpointURL = $url + "/mdm/tags/search?organizationgroupid=" + $Group
    $webTagsReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $header
    if($webTagsReturn) {
        write-host("Success.  Count = " + $webTagsReturn.Tags.TagName.count) -BackgroundColor Green
    }
    else {
        write-host("Failed.") -BackgroundColor Red
    }   
    return $WebTagsReturn
}

Function Create-AirwatchTag {
    param($TagName, $Group)
    Write-Host("Creating an Airwatch Tag $Tagname in OG ID $AirwatchGroupID : ") -NoNewline
    $quoteCharacter = [char]34
    $endpointURL = $url + "/mdm/tags/addtag"
    $CreateTagRequestObject = "{ " + $quoteCharacter + "LocationGroupID" + $quoteCharacter + ":" + $AirwatchGroupID + "," + $quoteCharacter + "TagName" + $quoteCharacter + ":" + $quoteCharacter + $Tagname + $quoteCharacter + "," + $quoteCharacter + "TagType" + $quoteCharacter + ":" + "1" + " }"
    $CreateTagReturn = Invoke-RestMethod -Method Post -Uri $endpointURL -Headers $header -Body $CreateTagRequestObject
    if($CreateTagReturn) {
        write-host("Success." + $CreateTagReturn) -BackgroundColor Green
    }
    else {
        write-host("Failed.") -BackgroundColor Red
    } 
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

$SystemInfo = get-wmiobject -class win32_bios
$SerialNumber = $SystemInfo.SerialNumber
$ModelTagName = ""
$ComputerSystemInfo = Get-WmiObject -Class Win32_ComputerSystem

if($SystemInfo.Manufacturer -like "*VMware*")
    {
    echo "VM found"
    $ManuTagName = "VM"
    $ModelTagName = "VM"
    }
elseif($SystemInfo.Manufacturer -like "*Dell*")
    {
    echo "Dell found"
    $ManuTagName = "Dell"
    }
elseif($SystemInfo.Manufacturer -like "*Microsoft*")
    {
    echo "Microsoft found"
    $ManuTagName = "Microsoft"
    }
elseif(($SystemInfo.Manufacturer -like "*HP*") -or ($SystemInfo.Manufacturer -like "*Hewlett*"))
    {
    echo "HP found"
    $ManuTagName = "HP"
    }
elseif($SystemInfo.Manufacturer -like "*Phoenix*")
    {
    echo "Phoenix found, possibly a VDI?"
    if($SystemInfo.SerialNumber -like "*VMware*")
        {
        $ManuTagName = "VDI"
        $ModelTagName = "VDI"
        }
    else
        {
        $ManuTagName = "Phoenix"
        }
    }
else
    {
    write-host "unknown manufacturer"
    }

if($ComputerSystemInfo.PCSystemType -eq 1) {
    $HardwareType = "Desktop"
}
elseif($ComputerSystemInfo.PCSystemType -eq 2) {
    $HardwareType = "Laptop"
}
elseif($ComputerSystemInfo.PCSystemType -eq 3) {
    $HardwareType = "Workstation"
}
elseif($ComputerSystemInfo.PCSystemType -eq 4) {
    $HardwareType = "Server"
}
else {
    $HardwareType = "unknown"
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
$AirwatchGroupID = Get-OrganizationGroupID -Name $AWOrganizationGroupName

#Get all the Airwatch tags in the specified OG
$AirwatchTags = Get-AirwatchTags -Group $AirwatchGroupID

#Get the Airwatch Device info for the local machine
$AirwatchDevice = Get-AirwatchDevice -Serial $SerialNumber
$AirwatchDeviceID = $AirwatchDevice.ID.Value
$AirwatchModel = $AirwatchDevice.Model

#If no device was found, then quit.
if(!$AirWatchDeviceID)
    {
    write-host "no device found, perhaps it is not enrolled?"
    exit
    }

# If the model is already set (from above as VM or VDI), we will use that for the tag name.  Otherwise, use the airwatch reported model.
if(!$ModelTagName)
    {
    $ModelTagName = $AirwatchModel
    }

#Check for existance of a tag for the device's model.  If not found, create it.  Either way, get the tag ID.
if($AirwatchTags.Tags.TagName -eq $ModelTagName)
    {  
    $AirwatchModelTagID = $($AirwatchTags.Tags | where-object { $_.TagName -eq $ModelTagName } | select-object Id).Id.Value
    write-host "Tag for $ModelTagName exists.  ID: $AirwatchModelTagID"
    }
else
    {
    $AirwatchModelTagID = Create-AirwatchTag -TagName $ModelTagName -Group $AirwatchGroupID
    write-host "Tag for $ModelTagName was not found. Created with ID: $AirwatchModelTagID"
    }

#Check for existance of a tag for the device's hardware type.  If not found, create it.  Either way, get the tag ID.
if($AirwatchTags.Tags.TagName -eq $HardwareType)
    {  
    $AirwatchHardwareTagID = $($AirwatchTags.Tags | where-object { $_.TagName -eq $HardwareType } | select-object Id).Id.Value
    write-host "Tag for $HardwareType exists.  ID: $AirwatchHardwareTagID"
    }
else
    {
    $AirwatchHardwareTagID = Create-AirwatchTag -TagName $HardwareType -Group $AirwatchGroupID
    write-host "Tag for $HardwareType was not found. Created with ID: $AirwatchHardwareTagID"
    }

#Get the tag ID of the manufacturer.
$AirwatchManuTagID = $($AirwatchTags.Tags | where-object { $_.TagName -eq $ManuTagName } | select-object Id).Id.Value

#Get Device IDs that were already tagged with the manufacturer tag we care about for comparison.  Tag current device if not already tagged.
$AirwatchManuTagDevices = Get-AirwatchTagDevices -TagID $AirwatchManuTagID
if($AirwatchManuTagDevices -eq $AirwatchDeviceID)
    {
    write-host "Device was already manufacture tagged appropriately"
    }
else
    {
    write-host "no match matching manufacturer tag - setting tag"
    $SetManuTagResult = Set-AirwatchDeviceTag -TagID $AirwatchManuTagID -DeviceID $AirwatchDeviceID
    }


#Get Device IDs that were already tagged with the model tag we care about for comparison.  Tag current device if not already tagged.
$AirwatchModelTagDevices = Get-AirwatchTagDevices -TagID $AirwatchModelTagID
if($AirwatchModelTagDevices -eq $AirwatchDeviceID)
    {
    $SetModelTagResult = "Device was already model tagged appropriately"
    write-host $SetModelTagResult
    }
else
    {
    write-host "no matching model tag - setting tag"
    $SetModelTagResult = Set-AirwatchDeviceTag -TagID $AirwatchModelTagID -DeviceID $AirwatchDeviceID
    }

#Get Device IDs that were already tagged with the hardare tag we care about for comparison.  Tag current device if not already tagged.
$AirwatchHardwareTagDevices = Get-AirwatchTagDevices -TagID $AirwatchHardwareTagID 
if($AirwatchHardwareTagDevices -eq $AirwatchDeviceID)
    {
    $SetHardwareTagResult = "Device was already hardware tagged appropriately"
    write-host $SetHardwareTagResult
    }
else
    {
    write-host "no matching hardware tag - setting tag"
    $SetHardwareTagResult = Set-AirwatchDeviceTag -TagID $AirwatchHardwareTagID -DeviceID $AirwatchDeviceID
    }

#Create a file for Airwatch to look for to know we ran successfully
$file = "C:\WINDOWS\Temp\Airwatch-SetDeviceTags-$version.log"
"Version: " + $version | out-file $file
"Device ID: " + $AirwatchDeviceID | Out-File $file -Append
"SerialNumber: " + $SerialNumber | Out-File $file -Append
"Hardware Type: " + $hardwaretype | Out-File $file -Append
"AW Tag ID: " + $AirwatchTagID | Out-File $file -Append
"AW Group ID: " + $AirwatchGroupID | out-file $file -Append
"Create Model Tag result: " + $CreateModelTagResult | out-file $file -Append
"Set Model Tag Result: " + $SetModelTagResult | out-file $file -append
"Set Manufacturer Tag Result: " + $SetManuTagResult | out-file $file -append
"Set Hardware Tag Result: " + $SetHardwareTagResult | out-file $file -append
