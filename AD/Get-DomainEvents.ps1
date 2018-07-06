Clear-Host
import-module activedirectory

$Domains = "<NETBIOS Domain name 1>", "<NETBIOS Domain name 2>"
$DaysToSearch = "1"
$EventIDs = "543", "550", "551", "567", "1018", "1019", "1021", "1021", "1022", "1206", "1216", "1605", "1811"

# Event IDs from https://support.microsoft.com/en-in/help/4042791/jet-database-errors-and-recovery-steps
#-543 JET_errRequiredLogFilesMissing
#-550 JET_errDatabaseDirtyShutdown
#-551 JET_errConsistentTimeMismatch
#-567 JET_errDbTimeTooNew
#-1018 JET_errReadVerifyFailure / Checksum error on a database page
#-1019 JET_errPageNotInitialized / Blank database page
#-1021 JET_errDiskReadVerificationFailure / The OS returned ERROR_CRC from file IO
#-1022 JET_errDiskIO / Disk IO error
#-1206 JET_errDatabaseCorrupted
#-1216 JET_errAttachedDatabaseMismatch
#-1605 JET_errKeyDuplicate / Illegal duplicate key
#-1811

foreach($Domain in $Domains)
    {
    $Results = @()
    $Controllers = Get-ADDomainController -Filter * -Server $Domain | select-object Hostname

    #write-host "$Domain Controllers"
    foreach($Controller in $Controllers)
        {
        foreach($ID in $EventIDs)
            {
            #write-host "Looking up $ID on $($Controller.Hostname)"
            $Results += Get-WinEvent -ComputerName $Controller.Hostname -FilterHashTable @{LogName='Directory Service'; StartTime=$((Get-Date).AddDays(-$DaysToSearch)); id=$ID} -InformationAction SilentlyContinue -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
            }
        }
    
        if($Results)
            {
            $Results | Group -Property ID | Select-Object Name, Count
            }
        else
            {
            write-host "No Results Found in $Domain"
            }
    }


