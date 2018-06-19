import-module activedirectory

$Server = "PrintServer Name"
$DaysToSearch = "2"
$users = @()
$results = Get-WinEvent -ComputerName $Server -FilterHashTable @{LogName="Microsoft-Windows-PrintService/Operational"; StartTime=$((Get-Date).AddDays(-$DaysToSearch)); ID=307}

foreach($result in $results) {
    $users += $(get-aduser -Identity $result.UserID).SamAccountName
    }

$users | select-object -Unique
