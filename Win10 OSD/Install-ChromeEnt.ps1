param (
	    [string]$ConfigFile = "Office365.xml",
        [string]$branch = "Semi-Annual"
	)

# Functions
function Write-LogEntry {
    param(
        [parameter(Mandatory=$true, HelpMessage="Value added to the Install-ChromeEnt.log file.")]
        [ValidateNotNullOrEmpty()]
        [string]$Value,

        [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = "Install-ChromeEnt.log"
    )
    # Determine log file location
    $LogFilePath = Join-Path -Path $env:windir -ChildPath "Temp\$($FileName)"

    # Add value to log file
    try {
        Add-Content -Value $Value -LiteralPath $LogFilePath -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to append log entry to Install-ChromeEnt.log file"
    }
}

$NetworkPath = "DFS_OR_UNC_NETWORK_LOCATION"
$LocalPath = "C:\Setup\Chrome"
$Chromex64 = "C:\Program Files\Google\Chrome\Application"
$Chromex86 = "C:\Program Files (x86)\Google\Chrome\Application"

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
Write-LogEntry "LocalPath: $LocalPath"
Write-LogEntry "Chrome x64: $Chromex64"
Write-LogEntry "Chrome x86: $Chromex86"

# Creating C:\Setup\Chrome
if(!(Test-Path $localPath))
    {
    Write-LogEntry "Creating $LocalPath"
    New-Item -ItemType Directory -Path $LocalPath
    }
else
    {
    Write-LogEntry "That's odd... $LocalPath already exists..."
    }

# Creating C:\Program Files\Google\Chrome\Application
if(!(Test-Path $Chromex64))
    {
    Write-LogEntry "Creating $Chromex64"
    New-Item -ItemType Directory -Path $Chromex64
    }
else
    {
    Write-LogEntry "That's odd... $Chromex64 already exists..."
    }

# Creating C:\Program Files (x86)\Google\Chrome\Application
if(!(Test-Path $Chromex86))
    {
    Write-LogEntry "Creating $Chromex86"
    New-Item -ItemType Directory -Path $Chromex86
    }
else
    {
    Write-LogEntry "That's odd... $Chromex86 already exists..."
    }

Write-LogEntry "Copying files from $NetworkPath to $LocalPath"
Copy-Item -Path $NetworkPath\* -Destination $LocalPath -Recurse -Force

Write-LogEntry "Contents of $LocalPath"
Write-Logentry "$(get-childitem $LocalPath)"

Write-LogEntry "Pre-install copying master_preferences file"
Copy-Item -Path "$LocalPath\master_preferences" -Destination $Chromex86 -Force
Copy-Item -Path "$LocalPath\master_preferences" -Destination $Chromex64 -Force

Write-LogEntry "Running install: msiexec.exe /q /i $LocalPath\googlechromestandaloneenterprise64.msi"
& msiexec.exe /q /i "$LocalPath\googlechromestandaloneenterprise64.msi"

Write-LogEntry "Waiting for the install to finish"
sleep 60

Write-LogEntry "Post-install copying master_preferences fils"
Copy-Item -Path "$LocalPath\master_preferences" -Destination $Chromex86 -Force
Copy-Item -Path "$LocalPath\master_preferences" -Destination $Chromex64 -Force

Write-LogEntry "Removing shortcut: c:\users\public\desktop\Google Chrome.lnk"
Remove-Item -Path "c:\users\public\desktop\Google Chrome.lnk" -Force