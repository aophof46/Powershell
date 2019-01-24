#https://somoit.net/windows/windows-add-secondary-ip-addresses-to-interface
$csv = Import-Csv -Path "$env:temp\backup-ipaddresses.csv"
foreach($row in $csv)
    {
    if(!(Get-NetIpAddress | where-object { $_.IPAddress -eq $row.IPAddress } ))
        {
        write-host "$($row.IPAddress) - good to add"
        #$row.IPAddress
        New-NetIPAddress -InterfaceIndex $row.ifIndex -IPAddress $row.IPAddress -PrefixLength $row.PrefixLength -SkipAsSource $True
        }
    else
        {
        write-host "$($row.IPAddress) - already exists"
        }
    }

