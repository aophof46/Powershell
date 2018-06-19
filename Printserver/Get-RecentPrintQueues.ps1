import-module activedirectory

$Server = "PrintServer Name"
$DaysToSearch = "2"
$users = @()
$printers = @()
$results = Get-WinEvent -ComputerName $Server -FilterHashTable @{LogName="Microsoft-Windows-PrintService/Operational"; StartTime=$((Get-Date).AddDays(-$DaysToSearch)); ID=307}

foreach($result in $results) {
    $printers += $([xml]$result.ToXml()).Event.UserData.DocumentPrinted.Param5
    }

$printers | select-object -unique | Sort-Object
