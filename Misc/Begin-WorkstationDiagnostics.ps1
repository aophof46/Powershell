$Date = Get-Date -UFormat %m-%d-%Y
$smtp = "exchangeserver.yourdomain.com"
$from = "email@domain.com"
$to = "youremail@domain.com"


$SendMail = $true

# Get Machine information

# Hostname
write-host "Getting hostname: " -NoNewline
$Machine = $env:computername
if($Machine) {
    write-host $Machine -BackgroundColor Green -ForegroundColor Black
}
else {
    write-host "Error getting hostname!" -BackgroundColor Red
}

# IP Address
write-host "Getting IP Address: " #-NoNewline
$IPAddress = Get-NetIPAddress
$IPAddressHTML = $IPAddress | where {($_.AddressFamily -eq "IPv4") -and ($_.IPAddress -ne "127.0.0.1")} | select InterfaceAlias, IPAddress | convertto-html -Fragment
if($IPAddress) {
    $Addresses = @()
    $Addresses = $IPAddress | where {($_.AddressFamily -eq "IPv4") -and ($_.IPAddress -ne "127.0.0.1")} #| select -expandproperty IPAddress
    foreach($Address in $Addresses) {
        write-host "$($Address.InterfaceAlias) : $($Address.IPAddress)" -BackgroundColor Green -ForegroundColor Black
    }
    #write-host "$($IPAddress | where {($_.AddressFamily -eq "IPv4") -and ($_.IPAddress -ne "127.0.0.1")} | select -expandproperty IPAddress)" -BackgroundColor Green -ForegroundColor Black
}
else {
    write-host "Error getting IP information!" -BackgroundColor Red
}

# Get disk space information
#Get-CimInstance -Class CIM_LogicalDisk | Select-Object * | Where-Object DriveType -EQ '3'
write-host "Collecting disk information: " -NoNewline
$DiskInfo = Get-CimInstance -Class Win32_LogicalDisk | Select-Object @{Name="Size(GB)";Expression={$_.size/1gb}}, @{Name="Free Space(GB)";Expression={$_.freespace/1gb}}, @{Name="Free (%)";Expression={"{0,6:P0}" -f(($_.freespace/1gb) / ($_.size/1gb))}}, DeviceID, DriveType | Where-Object DriveType -EQ '3'
$DiskInfoHTML = $DiskInfo | ConvertTo-Html -Fragment
if($DiskInfo) {
    write-host "Done." -BackgroundColor Green -ForegroundColor Black
}
else {
    write-host "Error!" -BackgroundColor Red
}

# Services
write-host "Collecting service information: " -NoNewline
$Services = get-service | select Name, DisplayName, Status, StartType | sort DisplayName
$ServicesHTML = $Services | ConvertTo-Html -Fragment
if($Services) {
    write-host "Done." -BackgroundColor Green -ForegroundColor Black
}
else {
    write-host "Error!" -BackgroundColor Red
}

# Installed updates
write-host "Getting installed updates: " -NoNewline
$InstalledUpdates = get-hotfix
$InstalledUpdatesHTML = $InstalledUpdates | select Description, HotFixID, InstalledBy, InstalledOn | sort HotFixID | ConvertTo-Html -Fragment
if($InstalledUpdates) {
    write-host "Done." -BackgroundColor Green -ForegroundColor Black
}
else {
    write-host "Failed!" -BackgroundColor Red
}
# GPUpdate
# This command generates no output
#Invoke-GPUpdate -Force
Write-Host "Updating Group Policy: " -NoNewline
$GPResultsStatus = ""
$GPResults = &"cmd.exe" "/c" "gpupdate /force"
$SuccessfulResults = "Updating policy...



Computer Policy update has completed successfully.

User Policy update has completed successfully."

if($GPResults -like $SuccessfulResult) {
    $GPResultsStatus = $true
    write-host "Successful." -BackgroundColor Green -ForegroundColor Black
}
else {
    $GPResultsStatus = $false
    write-host "Failed!" -BackgroundColor Red
}

$GPReultsHTML = "<p>" +  $GPResults


# Restarting explorer
write-host "Restarting Explorer... " -NoNewline
$ExplorerRestartStatus = Stop-Process -Name explorer -Force
write-host "Done." -BackgroundColor Green -ForegroundColor Black

# Test domain connectivity
Write-host "Testing computer secure channel: " -NoNewline
$SCResults = Test-ComputerSecureChannel
if($SCResults) {
    Write-Host "Good." -BackgroundColor Green -ForegroundColor Black
}
else {
    write-host "Failed!" -BackgroundColor Red
}

# Lets test DNS resolution
write-host "Testing DNS Resolution"
$DNSResultsArray = @()
$DomainNames = "$smtp", "www.yahoo.com", "www.google.com", "your.companywebsite.com", "this.one-is-supposed-to.fail"
foreach($DomainName in $DomainNames) {
    $obj = $Null
    $obj = New-Object System.Object

    $ResolveVar = ""
    $ResolveStatus = ""
    $ResolveIP = ""
    write-host "Resolving $DomainName... " -NoNewline
    $ResolveVar = Resolve-DnsName $DomainName -ErrorAction SilentlyContinue
    if($ResolveVar ) {
        $ResolveStatus = $true
        $ResolveIP = $ResolveVar.IP4Address
        Write-host $ResolveIP -BackgroundColor Green -ForegroundColor Black
    }
    else {
        $ResolveStatus  = $false
        $ResolveIP = "Failed!"
        Write-host $ResolveIP -BackgroundColor Red
    }
    $obj | Add-Member -Type NoteProperty -Name "DNS Name" -Value $DomainName
    $obj | Add-Member -Type NoteProperty -Name "Resolved" -Value $ResolveStatus
    $obj | Add-Member -Type NoteProperty -Name "Resolved IP" -Value $ResolveIP
    $DNSResultsArray += $obj
}
$DNSResultsArrayHTML = $DNSResultsArray | convertto-html -Fragment

# Get mapped network drives and their status
Write-host "Collecting mapped drive information: " -NoNewline
$Drives = Get-PSDrive | Where-Object {$_.Provider -like "*FileSystem*"} | select Name, Root, DisplayRoot | sort Name
$DrivesHTML = $Drives | ConvertTo-Html -Fragment
if($Drives) {
    write-host "Done." -BackgroundColor Green -ForegroundColor Black
}
else {
    write-host "Failed!" -BackgroundColor Red
}

# Write data to file and email it if desired
$NameOfReport = "$Machine Report"

# Source
$a = "<meta name=`"Source`" content=`"$([system.environment]::MachineName)`">`n"
# email style sheet
$a = $a + "<style>`n"
$a = $a + "body {color:#333333;}`n"
$a = $a + "table {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;width: 75%;}`n"
$a = $a + "th {text-align:left; font-weight:bold; border-width: 1px;padding: 5px;border-style: solid;border-color: black; color:#eeeeee; background-color:#333333;}`n"
$a = $a + "td {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}`n"
$a = $a + ".success { background-color: #66ff66; }`n"
$a = $a + ".warning { background-color: yellow; }`n"
$a = $a + ".failure { background-color: #ff6666; }`n"
$a = $a + ".inprocess { background-color: #00aaff; }`n"
$a = $a + "</style>`n"

$top = $a
$top += "<h3>" + $NameOfReport + " " + $(get-date).ToString() + "</h3>"

$body = ""
$body += "<p>IP Address information</p>"
$body += $IPAddressHTML

$body += ""
$body += "<p>DNS resolution results</p>"
$body += $DNSResultsArrayHTML 

$body += ""
$body += "<p>Policy update results</p>"
$body += $GPReultsHTML 

$body += ""
$body += "<p>Mapped drives information</p>"
$body += $DrivesHTML

$body += ""
$body += "<p>Domain connectivity results</p>"
$body += $SCResults 

$body += ""
$body += "<p>Disk information</p>"
$body += $DiskInfoHTML

$body += ""
$body += "<p>Installed updates</p>"
$body += $InstalledUpdatesHTML 

$body += ""
$body += "<p>Services information</p>"
$body += $ServicesHTML

$message = $top + $body

# Output to HTML file
$Filename = $Date + "_" + $Machine + ".html"
$Path = $ENV:USERPROFILE + "\Documents\"
set-content -path $($Path + $Filename) -Value $Message


if($SendMail) {
    Write-host "Mailing results to $to... "  -NoNewline

    $Outlook = New-Object -ComObject Outlook.Application
    $Mail = $Outlook.CreateItem(0)

    $Mail.To = $to
    $Mail.Subject = $NameOfReport
    $Mail.HTMLBody = $message

    try {
        $Mail.send()
        write-host "Done." -BackgroundColor Green -ForegroundColor Black
    }
    catch {
        write-host " Failed." -BackgroundColor Red
    }
}

# Pause before ending so user can view the results
write-host "End of script.  Hit enter to close window" -BackgroundColor Green -ForegroundColor Black
 &"cmd.exe" "/c" "pause"
