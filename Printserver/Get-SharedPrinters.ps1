param (
	[string]$ComputerName = "localhost"
	)
 
if($ComputerName -notmatch "localhost")
    {
    $creds = Get-Credential
    }

function Get-SharedPrinters($strComputer)
{
    # "Printer Share"
    if($creds)
        {
        $colItems = GWMI -cl "Win32_Printer" -credential $creds -name "root\CimV2" -comp $strComputer -Filter "Shared = TRUE"
        }
    else
        {
        $colItems = GWMI -cl "Win32_Printer" -name "root\CimV2" -comp $strComputer -Filter "Shared = TRUE"
        }
    
    ForEach ($objItem in $colItems) 
        {
        $h = "" | select Name,Share
        $PrintServerName = $objItem.__Server
        $PrinterShareName = $objItem.ShareName
        $PrinterName = $objItem.DeviceID
        $SharePath = "\\$PrintServerName\$PrinterShareName"    
        $h.Name = $PrinterName
        $h.Share = $SharePath
        $h
        }
}

$SomeHash = @{}
$SomeHash = Get-SharedPrinters($ComputerName)
$SomeHash

