# Functions
function Write-LogEntry {
    param(
        [parameter(Mandatory=$true, HelpMessage="Value added to the ITShortcut.log file.")]
        [ValidateNotNullOrEmpty()]
        [string]$Value,

        [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = "ITShortcut.log"
    )
    # Determine log file location
    $LogFilePath = Join-Path -Path $env:windir -ChildPath "Temp\$($FileName)"

    # Add value to log file
    try {
        Add-Content -Value $Value -LiteralPath $LogFilePath -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to append log entry to ITShortcut.log file"
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
Write-LogEntry "Windows direcotry: $WINDIR"
Write-LogEntry "Program Files: $PROGRAMFILES"
Write-LogEntry "All Users: $ALLUSERS"
Write-LogEntry "System Drive: $SYSDRIVE"
Write-LogEntry "OS Version: $OSVersion"
Write-LogEntry "Date: $date"
Write-LogEntry "Computer Manufacturer: $($cs.manufacturer)"
Write-logEntry "Computer Model: $($cs.model)"
Write-LogEntry "Computer Name: $($cs.name)"
Write-LogEntry "Computer Owner: $($cs.PrimaryOwnerName)"

#file paths for Internet Explorer
$iePath = "$PROGRAMFILES\Internet Explorer\iexplore.exe"
$ieLnk = "$APPDATA\Microsoft\Windows\Start Menu\Programs\Accessories\Internet Explorer.lnk"

# Create IE shortcut 
if(!(Test-Path $ieLnk))
    {
    if(Test-Path $iePath)
        {
        Write-LogEntry "creating shortcut for $iePath at $ieLnk"
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ieLnk)
        $Shortcut.TargetPath = $iePath
        $Shortcut.Save()
        }
    else
        {
        Write-LogEntry "$iePath does not exist"
        }
    }
else
    {
    Write-LogEntry "$ieLnk exists"
    }
