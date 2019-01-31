# Functions
function Write-LogEntry {
    param(
        [parameter(Mandatory=$true, HelpMessage="Value added to the OEMInfo.log file.")]
        [ValidateNotNullOrEmpty()]
        [string]$Value,

        [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = "OEMInfo.log"
    )
    # Determine log file location
    $LogFilePath = Join-Path -Path $env:windir -ChildPath "Temp\$($FileName)"

    # Add value to log file
    try {
        Add-Content -Value $Value -LiteralPath $LogFilePath -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to append log entry to OEMInfo.log file"
    }
}

$ScriptPath = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)

$WINDIR=$env:WINDIR
$PROGRAMFILES=$env:ProgramW6432
$ALLUSERS = $env:ALLUSERSPROFILE
$APPDATA = $env:APPDATA
$SYSDRIVE = $env:SystemDrive
$OSversion = [System.Environment]::OSVersion.Version.Build
$date=Get-Date -format M-d-yy
$cs = Get-WmiObject -Class Win32_ComputerSystem

Write-LogEntry "Script path: $ScriptPath"
Write-LogEntry "Windows directory: $WINDIR"
Write-LogEntry "Program Files: $PROGRAMFILES"
Write-LogEntry "All Users: $ALLUSERS"
Write-LogEntry "System Drive: $SYSDRIVE"
Write-LogEntry "OS Version: $OSVersion"
Write-LogEntry "Date: $date"
Write-LogEntry "Computer Manufacturer: $($cs.manufacturer)"
Write-logEntry "Computer Model: $($cs.model)"
Write-LogEntry "Computer Name: $($cs.name)"
Write-LogEntry "Computer Owner: $($cs.PrimaryOwnerName)"

#################################################################################################################################
# Support Information
#copy-item -Force $ScriptPath\oemlogo.bmp "$WINDIR\system32\oemlogo.bmp"

$manufacturer = $cs.Manufacturer
$model = $cs.Model
if($manufacturer -like "VMware*")
    {
    Write-LogEntry "Copying vmwarelogo.bmp to $WINDIR\system32\oemlogo.bmp"
    copy-item -Force $ScriptPath\vmwarelogo.bmp "$WINDIR\system32\oemlogo.bmp"
    }
elseif($manufacturer -like "*Dell*")
    {
    Write-LogEntry "Copying delllogo.bmp to $WINDIR\system32\oemlogo.bmp"
    copy-item -Force $ScriptPath\delllogo.bmp "$WINDIR\system32\oemlogo.bmp"
    }
elseif($manufacturer -like "*HP*")
    {
    Write-LogEntry "Copying hplogo.bmp to $WINDIR\system32\oemlogo.bmp"
    copy-item -Force $ScriptPath\hplogo.bmp "$WINDIR\system32\oemlogo.bmp"
    }
else
    {
    Write-LogEntry "Copying genericlogo.bmp to $WINDIR\system32\oemlogo.bmp"
    copy-item -Force $ScriptPath\genericlogo.bmp "$WINDIR\system32\oemlogo.bmp"
    }


if(-not (Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\OEMInformation"))
    {
    New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion" -Name "OEMInformation"
    }

New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\OEMInformation" -Name Logo -PropertyType String -Value "%systemroot%\system32\OEMLogo.bmp" -Force
New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\OEMInformation" -Name Manufacturer -PropertyType String -Value "$manufacturer" -Force
New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\OEMInformation" -Name Model -PropertyType String -Value "$model" -Force
#New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\OEMInformation" -Name SupportPhone -PropertyType String -Value "(555) 867-5309" -Force
#################################################################################################################################
