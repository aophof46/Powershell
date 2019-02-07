# Functions
function Write-LogEntry {
    param(
        [parameter(Mandatory=$true, HelpMessage="Value added to the Copy-StartMenu.log file.")]
        [ValidateNotNullOrEmpty()]
        [string]$Value,

        [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = "Copy-StartMenu.log"
    )
    # Determine log file location
    $LogFilePath = Join-Path -Path $env:windir -ChildPath "Temp\$($FileName)"

    # Add value to log file
    try {
        Add-Content -Value $Value -LiteralPath $LogFilePath -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to append log entry to Copy-StartMenu.log file"
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


if("$ScriptPath\LayoutModification.xml")
    {
    Write-LogEntry "LayoutModification file found, copying now"
    Import-StartLayout -LayoutPath $ScriptPath\LayoutModification.xml -MountPath $env:SystemDrive\
    # Copy, rather than import, Start Menu and Taskbar Layout
    # Copy-Item -Path "$ScriptPath\LayoutModification.xml" -Destination "$env:SystemDrive\Default\AppData\Local\Microsoft\Windows\Shell\" -Force
    }
else
    {
    Write-LogEntry "LayoutModification file not found in $ScriptPath"
    }
