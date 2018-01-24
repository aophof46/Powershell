#$Printers = Get-WMIObject Win32_Printer -Filter "(Local = $true) and (Shared = $true)"
$Printers = Get-Printer | where-object { ($_.Type -match "local") -and ($_.Shared -match "True") }
$PrinterPorts = Get-PrinterPort | where-object { $_.PortMonitor -match "TCPMON.DLL" }

# Delete all print jobs
Do
    {
    restart-service -Name Spooler
    Get-WmiObject Win32_Printer <# -Filter "(Local = $true) and (Shared = $true)" #> | ForEach-Object {$_.CancelAllJobs()}
    restart-service -Name Spooler
    }
While 
    (
    Get-WmiObject Win32_PrintJob
    )

foreach ($Printer in $Printers)
    {
    Do
        {
        Remove-Printer $Printer
        }
    while
        (
        #get-wmiobject win32_printer | where-object {$_.Name -match $Printer.name }
        Get-Printer -Name $Printer.Name
        )
    }

foreach ($PrinterPort in $PrinterPorts)
    {
    Do
        {
        Remove-PrinterPort -Name $PrinterPort.Name
        }
    While
        (
        Get-PrinterPort -Name $PrinterPort.Name
        )
    }