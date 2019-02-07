param (
	    [string]$ConfigFile = "Office365.xml",
        [string]$branch = "Semi-Annual"
	)

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

$NetworkPath = "DFS_OR_UNC_NETWORK_LOCATION"

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
Write-LogEntry "Network Path: $NetworkPath"
Write-LogEntry "Config File: $ConfigFile"
Write-LogEntry "Branch: $branch"

if($branch -eq "monthly")
    {
    Write-LogEntry "$branch branch specified"
    $NetworkPath = "$NetworkPath\o365-2016-Monthly"
    }
else
    {
    Write-LogEntry "Default branch of semi-annual chosen"
    $NetworkPath = "$NetworkPath\o365-2016-Semi-Annual"
    }

$LocalPath = "C:\Setup\Office365"

if(!(Test-Path $localPath))
    {
    Write-LogEntry "Creating $LocalPath"
    New-Item -ItemType Directory -Path $LocalPath
    }
else
    {
    Write-LogEntry "That's odd... $LocalPath already exists..."
    }

Write-LogEntry "Copying o365 files from $NetworkPath to $LocalPath"
Copy-Item -Path $NetworkPath\* -Destination $LocalPath -Recurse -Force

Write-LogEntry "Contents of $LocalPath"
Write-Logentry "$(get-childitem C:\setup\Office365)"

$SetupEXE = "$LocalPath\setup.exe"
$CONFIGURATIONFILE = "$LocalPath\MDTConfig\$ConfigFile"

Write-LogEntry "Executing $SetupEXE /CONFIGURE $CONFIGURATIONFILE"
& $SetupEXE /CONFIGURE $CONFIGURATIONFILE