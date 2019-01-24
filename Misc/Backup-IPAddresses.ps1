$IPAddresses = @()
$NetAdapters = Get-NetAdapter
foreach($NetAdapter in $NetAdapters)
    {
    $IPAddresses += Get-NetIPAddress | where-object { ($_.InterfaceIndex -eq $NetAdapter.IfIndex) -and ($_.AddressFamily -eq "IPv4") }
    }
$IPAddresses | export-csv -Path "$env:temp\backup-ipaddresses.csv"
