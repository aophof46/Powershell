# Functions
function Write-LogEntry {
    param(
        [parameter(Mandatory=$true, HelpMessage="Value added to the Install-AdobeReaderDC.log file.")]
        [ValidateNotNullOrEmpty()]
        [string]$Value,

        [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = "Install-AdobeReaderDC.log"
    )
    # Determine log file location
    $LogFilePath = Join-Path -Path $env:windir -ChildPath "Temp\$($FileName)"

    # Add value to log file
    try {
        Add-Content -Value $Value -LiteralPath $LogFilePath -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to append log entry to Install-AdobeReaderDC.log file"
    }
}

$NetworkPath = "DFS_OR_UNC_NETWORK_LOCATION"
$LocalPath = "C:\Setup\Adobe\Reader DC"


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

# Creating local dir
if(!(Test-Path $localPath))
    {
    Write-LogEntry "Creating $LocalPath"
    New-Item -ItemType Directory -Path $LocalPath
    }
else
    {
    Write-LogEntry "That's odd... $LocalPath already exists..."
    }


Write-LogEntry "Copying files from $NetworkPath to $LocalPath"
Copy-Item -Path $NetworkPath\* -Destination $LocalPath -Recurse -Force

Write-LogEntry "Contents of $LocalPath"
Write-Logentry "$(get-childitem $LocalPath)"

Write-LogEntry "Running install: msiexec.exe /q /i $LocalPath\acroread.msi"
& msiexec.exe /q /i "$LocalPath\acroread.msi" | Out-Null

Write-LogEntry "Running install: msiexec.exe /update $LocalPath\AcroRdrDCUpd1801120036.msp /qn"
& msiexec.exe /update "$LocalPath\AcroRdrDCUpd1801120036.msp" /qn | Out-Null

#Write-LogEntry "Waiting for the install to finish"
#sleep 60

#Write-LogEntry "Removing shortcut: c:\users\public\desktop\Google Chrome.lnk"
#Remove-Item -Path "c:\users\public\desktop\Google Chrome.lnk" -Force