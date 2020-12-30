 #Description:  New users are created in the New Accounts OU.  Sometimes we forget to move them to the right OU.  This is a reminder script.

# Import the Active Directory module.
If ( ! (Get-module ActiveDirectory )) {Import-Module ActiveDirectory}
If ( ! (Get-module ActiveDirectory )) {Write-Host -foreground "Red" "`r`nActive Directory Module could not be loaded.`r`n"; break}

$smtp = "internal.mailserver.com"
$from = "where@thiswassent.from"
$to = "who@tosend.to"

$NumOfDays = "-7"
$NameOfReport = "New users still in the `"New Users`" OU"
$date = (get-date).AddDays($NumOfDays)

$ServerPowershellUNC = "\\location\to\my\functions"
if(test-path $ServerPowershellUNC)
    {
	Import-Module "$ServerPowershellUNC\Function_Get-GlobalCatalog.ps1" -Force
    Import-Module "$ServerPowershellUNC\Function_Get-ADForestInfo.ps1" -Force
    }
else
    {
    write-host "Unable to find modules"
    exit
    }
    
# Get a global catalog server
$GC = Get-GlobalCatalog
$DomainInfo = Get-ADForestInfo
$Users = @()

foreach($Domain in $DomainInfo) {
    try {
        $NewAccountsOU = Get-ADOrganizationalUnit -server $domain.Domain -Filter 'Name -like "New Accounts"'
        $Users += get-aduser -server $domain.domain -SearchBase $NewAccountsOU -Properties * -Filter { whenCreated -gt $date } | select-object name, samaccountname, canonicalname, mail, whenCreated
    }
    catch {
        $Users = "An error occured"
    }
}

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

if($Users) {
    $message = $top + $($Users | ConvertTo-Html -Fragment)
    send-mailmessage -from $from -to $to -subject $NameOfReport -body $message -smtpServer $smtp -bodyashtml
}
 
