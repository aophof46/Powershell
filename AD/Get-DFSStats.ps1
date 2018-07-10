# Note: RSAT DFS management tools need to be installed on the PC this runs on.
$ReplicationServers = "dfsserver1.fqdn", "dfsserver2.fqdn"
$StatusFile = "C:\temp\dfs-output.htm"


$DFSRoots = @()
$DFSRootTargets = @()
$ReplicationStatusArray = @()
$RGroups = @() 

# Get DFS Namespace data
foreach ($RServer in $ReplicationServers)
    {
    $DFSRoots += get-dfsnroot -Computername $RServer | select-object -Property *
    }
foreach($DFSRoot in $DFSRoots)
    {
    $DFSRootTargets += Get-DfsnRootTarget -Path $DFSRoot.Path | Select-Object -Property *
    }

# Get Replication status
foreach ($RServer in $ReplicationServers)
    {
    $RGroups += Get-WmiObject  -Namespace "root\MicrosoftDFS" -Computername $RServer -Query "SELECT * FROM DfsrReplicationGroupConfig"
    }
       
$Succ=0
$Warn=0
$Err=0
foreach ($Group in $RGroups)
{ 
    $RGFoldersWMIQ = "SELECT * FROM DfsrReplicatedFolderConfig WHERE ReplicationGroupGUID='" + $Group.ReplicationGroupGUID + "'"
    $RGFolders = Get-WmiObject -Namespace "root\MicrosoftDFS" -Query  $RGFoldersWMIQ -ComputerName $Group.PSComputerName
    $RGConnectionsWMIQ = "SELECT * FROM DfsrConnectionConfig WHERE ReplicationGroupGUID='"+ $Group.ReplicationGroupGUID + "'"
    $RGConnections = Get-WmiObject -Namespace "root\MicrosoftDFS" -Query  $RGConnectionsWMIQ -ComputerName $Group.PSComputerName
    foreach ($Connection in $RGConnections)
    {
        $ConnectionName = $Connection.PartnerName#.Trim()
        if ($Connection.Enabled -eq $True)
        {
            #if (((New-Object System.Net.NetworkInformation.ping).send("$ConnectionName")).Status -eq "Success")
            #{
                foreach ($Folder in $RGFolders)
                {
                    $RGName = $Group.ReplicationGroupName
                    $RFName = $Folder.ReplicatedFolderName
 
                    if ($Connection.Inbound -eq $True)
                    {
                        $SendingMember = $ConnectionName
                        $ReceivingMember = $Group.PSComputerName
                        $Direction="inbound"
                    }
                    else
                    {
                        $SendingMember = $Group.PSComputerName
                        $ReceivingMember = $ConnectionName
                        $Direction="outbound"
                    }
 
                    $BLCommand = "dfsrdiag Backlog /RGName:'" + $RGName + "' /RFName:'" + $RFName + "' /SendingMember:" + $SendingMember + " /ReceivingMember:" + $ReceivingMember
                    $Backlog = Invoke-Expression -Command $BLCommand
 
                    $BackLogFilecount = 0
                    foreach ($item in $Backlog)
                    {
                        if ($item -ilike "*Backlog File count*")
                        {
                            $BacklogFileCount = [int]$Item.Split(":")[1].Trim()
                        }
                    }
 
                    if ($BacklogFileCount -eq 0)
                    {
                        $Color="white"
                        $Succ=$Succ+1
                    }
                    elseif ($BacklogFilecount -lt 10)
                    {
                        $Color="yellow"
                        $Warn=$Warn+1
                    }
                    else
                    {
                        $Color="red"
                        $Err=$Err+1
                    }
                    $ReplicationStatus = new-object System.Object
                    $ReplicationStatus | add-member -type NoteProperty -name "Sending Member" -Value $SendingMember
                    $ReplicationStatus | add-member -type NoteProperty -name "Receiving Member" -Value $ReceivingMember
                    $ReplicationStatus | add-member -type NoteProperty -name "Replication Group" -Value $RGName
                    $ReplicationStatus | add-member -type NoteProperty -name "Backlog" -value $BacklogFileCount
                    $ReplicationStatusArray += $ReplicationStatus 
                    
                } # Closing iterate through all folders
            #} # Closing  If replies to ping
        } # Closing  If Connection enabled
    } # Closing iteration through all connections
} # Closing iteration through all groups

$NamespaceHTML = $DFSRootTargets | Select-object -Property Path, TargetPath, State | sort-object "Path" | ConvertTo-Html -Fragment
$NamespaceHTML = $NamespaceHTML -replace "Offline","<font color=red>Offline</font>"
$NamespaceHTML = $NamespaceHTML -replace "Online","<font color=green>Online</font>"

$ReplicationHTML = $ReplicationStatusArray | Sort-Object "Replication Group" | ConvertTo-Html -Fragment
$ReplicationHTML = $ReplicationHTML -replace "</td><td>([0]{1})</td></tr>",$("</td><td><font color=green>"+'$1'+"</font></td></tr>")
$ReplicationHTML = $ReplicationHTML -replace "</td><td>([1-9]{1})</td></tr>",$("</td><td><font color=yellow>"+'$1'+"</font></td></tr>")
$ReplicationHTML = $ReplicationHTML -replace "</td><td>([1-9]{2,})</td></tr>",$("</td><td><font color=red>"+'$1'+"</font></td></tr>")

$ReportHTML = ""
$ReportHTML += "<p><strong>DFS Namespace Status</strong></p>"
$ReportHTML += $NamespaceHTML 
$ReportHTML += "<br>"
$ReportHTML += "<p><strong>DFS Replication Status</strong></p>"
$ReportHTML += $ReplicationHTML
$ReportHTML += "<br>"

$ReportHTML | out-file -FilePath $StatusFile -Append
