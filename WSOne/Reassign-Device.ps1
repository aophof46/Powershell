#---------------------------------------------------------------------------

# Originally by
#Bertrand TANNE 12/05/2020 |
# re-written 9/21/2020

#Demande un N° de serie de device a modifier |
#Et demande le user cible |

#Request a serial number of device to modify
#And ask the target user

#---------------------------------------------------------------------------

param (

[string]$CN ='fill in your cn number',

[string]$Tenant = 'put you own one',

[bool]$Asking=$True

)

$version = 2

Write-Host "---- Start of script -----"

# Proxy
$Wcl = new-object System.Net.WebClient
$Wcl.Headers.Add(“user-agent”, “PowerShell Script”)
$Wcl.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials


# Initialization of JSON Headers
$headersV1 = @{
"Authorization" = ""
"aw-tenant-code" = $Tenant
"Accept" = 'application/json;version=1'
"Content-Type" = 'application/json'
}

$headersV2 = @{
"Authorization" = ""
"aw-tenant-code" = $Tenant
"Accept" = 'application/json;version=2'
"Content-Type" = 'application/json'
}

# Validation of credentials
try{
    #authentication window
    $cred = Get-Credential
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($cred.Password)
    $encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$($cred.UserName):$([System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr))"))
    $headersV1.Authorization="Basic $encodedCreds"
    $headersV2.Authorization="Basic $encodedCreds"
    $Url="https://as"+$CN+".awmdm.com/API/system/info"
    $webReturn = Invoke-RestMethod -Method Get -Uri $Url -Headers $headersV1
}

catch {
    write-host "Login / Password error"
    break
}

write-host "Login WSO OK"
$currentdevice=$null
$SerialNumber = Read-Host -Prompt 'Enter the serial number to reassign:'

Write-Host "Searching for device "
$Url = "https://as"+$CN+".awmdm.com/API/mdm/devices?searchBy=SerialNumber&id="+[string]$SerialNumber
$webReturnDevice = Invoke-RestMethod -Method Get -Uri $Url -Headers $headersV1

write-host $webReturnDevice

# Get Old User
$OldCodeID = $webReturnDevice.UserName
$Url = "https://as"+$CN+".awmdm.com/API/system/users/search?username=" + $OldCodeID
$webReturnOldUser = Invoke-RestMethod -Method Get -Uri $Url -Headers $headersV1

# Get New User
$NewCodeId = Read-Host -Prompt 'Enter the new username:'
$Url = "https://as"+$CN+".awmdm.com/API/system/users/search?username=" + $NewCodeId
$webReturnNewUser = Invoke-RestMethod -Method Get -Uri $Url -Headers $headersV1

$NewUsersIdValue = ''

if ($webReturnNewUser.Users.Count -eq 0) {
    $NewUsersIdValue = "stagingwk001"
    Write-Host "User not found in WSO!" -ForegroundColor Red
} 
else {
    if ($webReturnNewUser.Users.Count -eq 1) {
        $NewUsersIdValue = $webReturnNewUser.Users.id.value
    } 
    else {
        #Select a user froma a list of returned WSO users
        Write-Host "Multiple users found!" -ForegroundColor Red
        foreach ($User in $webReturnNewUser.Users) {
            Write-host $User.id.Value $User.UserName $User.FirstName $User.LastName $User.Status $User.Email $User.Group $User.LocationGroupId $User.OrganizationGroupUuid $User.EnrolledDevicesCount
        }

        if ($Asking){
            $NewUsersIdValue = Read-Host -Prompt 'Enter the desired ID: '
        }

    }

    #Only if the WSO user is valid
    write-host "Reassigning to user: " $NewUsersIdValue $webReturnNewUser.Users.email

    $NewFirst = $webReturnNewUser.Users.Firstname
    $NewLast = $webReturnNewUser.Users.LastName
    
    $OldFirst = $webReturnOldUser.Users.FirstName
    $OldLast = $webReturnOldUser.Users.LastName
    
    #User reassignment
    $Confirm = "N"
    $default = $Confirm

    if ($Asking){
        if (!($Confirm = Read-Host "Confirm user reassignment [$default]")) { $Confirm = $default }
    }

    if($Confirm -eq "Y"){

        # Change enrollment user
        $deviceID = $webReturnDevice.Id.value
        $URLChangeUser = "https://as" + $CN + ".awmdm.com/API/mdm/devices/$($deviceID)/enrollmentuser/$($NewUsersIdValue)"
        Write-host $URLChangeUser
        $WebreturnChangeUser = Invoke-RestMethod -Method PATCH -Uri $URLChangeUser -headers $headersV1

        #Change Friendly Name $Device.DeviceFriendlyName
        $NewDeviceFriendlyName = $webReturnDevice.DeviceFriendlyName -replace "$OldFirst $OldLast", "$NewFirst $NewLast"

        #create JSON
        $quoteCharacter = [char]34
        $DeviceFriendlyNameJSON = "{ " + $quoteCharacter + "DeviceFriendlyName" + $quoteCharacter +": " + $quoteCharacter + $NewDeviceFriendlyName + $quoteCharacter + "}"
        $URLChangeFriendlyName = "https://as" + $CN + ".awmdm.com/API/mdm/devices/"+$deviceID
        $WebreturnChangeFriendlyName = Invoke-RestMethod -Method PUT -Uri $URLChangeFriendlyName -headers $headersV1 -Body $DeviceFriendlyNameJSON
    }

}
