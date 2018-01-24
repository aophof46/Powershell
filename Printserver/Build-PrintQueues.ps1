param([string]$script = "build_template.csv")

# CSV format
# Driver,Portname,IPAddress,SNMP,Sharename,Location,Comment,Printername

Function Get-IP 
    {
    PARAM   ([string]$HostName="")
    PROCESS {TRAP 
                 {"" ;continue} 
                 [system.net.dns]::gethostaddresses($HostName) | where {$_.AddressFamily -eq "InterNetwork"} | select -ExpandProperty IPAddressToString
            }
    }

$ServerName = $env:COMPUTERNAME 
$ServerIP = Get-IP $ServerName
$IPPrefix = $ServerIP.Trimend("1234567890")
$ServerInfo = gwmi Win32_OperatingSystem  -ComputerName $ServerName #| select caption
$prnScriptPath = "$env:SystemRoot\System32\Printing_Admin_Scripts\en-US"
$cscriptPath =  "$env:SystemRoot\System32\cscript.exe"

$printers = import-csv $script


#
# Check to make sure the necessary drivers are on the server
#
$PrintDrivers = $printers | Sort-Object {$_.Driver} -unique
foreach ($PrintDriver in $PrintDrivers) 
    {
    $DriverMatch = Get-WMIObject -Class Win32_PrinterDriver -Computer $ServerName | Select Name | where { $_.Name -match $PrintDriver.Driver}
    if(!$DriverMatch) 
        {
        write-host "$($PrintDriver.driver) not found on $ServerName"
        Break
        }
    }


foreach ($printer in $printers) 
    {

    $TempName = $printer.Printername
    $TempDriver = $printer.Driver
    $TempIPAddress = $IPPrefix + $printer.IPAddress  
    $TempPortName = "IP_" + $TempIPAddress 
    $TempShareName = $TempName
    $TempLocation = $printer.Location 
    $TempComment = $printer.Comment 
    $TempSNMP = $printer.SNMP

    # Create Printer Port
    if(!Get-PrinterPort -Name $TempPortName -ErrorAction SilentlyContinue)
        {
        Add-PrinterPort -Name $TempPortName -PrinterHostAddress "$TempIPAddress" -SNMP 1 -SNMPCommunity "public"
        if($TempSNMP -eq $false) 
            {
            if((test-path "$prnScriptPath\prnport.vbs") -or (test-path $cscriptPath))
                {
                $arguments = "-t -r $TempPortName -md"
                start-process $cscriptPath $prnScriptPath"\prnport.vbs $arguments"
                }
            else
                {
                write-host "SNMP: No printing scripts available.  SNMP must be manually disabled for $TempName printer."
                }
            }
        }
    
    # Create Printer
    if((Get-PrinterPort -Name $TempPortName -ErrorAction SilentlyContinue) -and !(Get-Printer -Name $TempName -ErrorAction SilentlyContinue))
        {
        Add-Printer -Name $TempName -DriverName $TempDriver -Shared -ShareName $TempShareName -PortName $TempPortName -Location $TempLocation -Comment $TempComment
        }
    Else
        {
        write-host "Port $TempPortName not found or Printer $TempName already exists"
        }

}

