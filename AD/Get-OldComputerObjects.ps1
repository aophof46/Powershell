import-module activedirectory 
$domain = "DOMAIN"
$DaysInactive = 90 
$time = (Get-Date).Adddays(-($DaysInactive))
 
# Get all AD computers with lastLogonTimestamp less than our time
Get-ADComputer -server $domain -Filter {LastLogonTimeStamp -lt $time} -Properties LastLogonTimeStamp |
 
# Output hostname and lastLogonTimestamp into CSV
select-object Name,@{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp)}} | export-csv c:\temp\OLD_Computer.csv -notypeinformation
