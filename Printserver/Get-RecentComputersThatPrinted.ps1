import-module activedirectory

$Server = "<Printserver name"
$DaysToSearch = "2"
$pattern = "on \w*-{1}\w* was printed"
$messages = @()
$results = Get-WinEvent -ComputerName $Server -FilterHashTable @{LogName="Microsoft-Windows-PrintService/Operational"; StartTime=$((Get-Date).AddDays(-$DaysToSearch)); ID=307}

foreach($result in $results) {
    $messages += $($result.message | select-string -pattern $pattern | foreach { $_.Matches.Value }) -replace "on " -replace " was printed"
    }

$messages | Select-Object -Unique
