# Get the Dell warranty end date for WS One devices in a specified OG

#Dell API stuff
$DellApiKey = "DELL API KEY HERE"
$DellClientSecret = "DELL API CLIENT SECRET HERE"

$version = 1
$AirwatchServer = "https://asNNNN.awmdm.com" 
$AirwatchUser = "AW USER NAME HERE" 
$AirwatchPW = "AW USER PW HERE" 
$AirwatchAPIKey = "API KEY HERE" 
$AWOrganizationGroupName = "OG NAME HERE"

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

$ServerPowershellUNC = "UNC PATH TO FILE HERE"
if(test-path $ServerPowershellUNC)
    {
    Import-Module "$ServerPowershellUNC\Function_Get-DellWarranty.ps1"
    }
else
    {
    write-host "Unable to find modules"
    exit
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
    
Function Get-OrganizationGroupID {
        param($Name)
        Write-Host("Getting Group ID from Group Name")
        $endpointURL = $URL + "/system/groups/search?groupid=" + $Name
        $WebGroupReturn = Invoke-RestMethod -Method Get -Uri $endpointURL -Headers $header
        $groupID = $WebGroupReturn.LocationGroups.Id.Value 
        Return $groupID
}

#Get the Group ID for the specified OG name
$AirwatchGroupID = Get-OrganizationGroupID -Name $AWOrganizationGroupName

#Get all the devices, then filter down to just Dell devices
$OGDevices = Get-AirwatchDevices -groupID $AirwatchGroupID
$DellDevices = $OGDevices.devices | where-object {$_.OEMInfo -like "*Dell*"}

$ResultsArray = @()
foreach($DellDevice in $DellDevices) {
    $obj = $Null
    $obj = New-Object System.Object

    try{
        $WarrantyInfo = Get-DellWarrantyInfo -ServiceTags $($DellDevice.SerialNumber) -ApiKey $DellApiKey -KeySecret $DellClientSecret
    }
    catch {
        $WarrantyInfo = "error with Dell API"
    }
    #write-host "##########"
    #write-host "Friendly Name: " $DellDevice.DeviceFriendlyName
    #write-host "Reported Name: " $DellDevice.DeviceReportedName
    #write-host "Serial Number: " $DellDevice.SerialNumber
    #write-host "Warranty: " $WarrantyInfo
    
    $obj | Add-Member -Type NoteProperty -Name "Friendly Name" -value $DellDevice.DeviceFriendlyName
    $obj | Add-Member -Type NoteProperty -Name "Reported Name" -value $DellDevice.DeviceReportedName
    $obj | Add-Member -Type NoteProperty -Name "Dell Serial" -value $DellDevice.SerialNumber
    $obj | Add-Member -Type NoteProperty -Name "Warranty Info" -value $WarrantyInfo

    $resultsarray += $obj
}

if($ResultsArray) {
    $resultsarray | export-csv -path "c:\temp\$AWOrganizationGroupName-airwatchdellwarranty.csv" -notypeinformation
}
