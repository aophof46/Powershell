# Functions
function Write-LogEntry {
    param(
        [parameter(Mandatory=$true, HelpMessage="Value added to the Add-RightClickRunAs.log file.")]
        [ValidateNotNullOrEmpty()]
        [string]$Value,

        [parameter(Mandatory=$false, HelpMessage="Name of the log file that the entry will written to.")]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = "Add-RightClickRunAs.log"
    )
    # Determine log file location
    $LogFilePath = Join-Path -Path $env:windir -ChildPath "Temp\$($FileName)"

    # Add value to log file
    try {
        Add-Content -Value $Value -LiteralPath $LogFilePath -ErrorAction Stop
    }
    catch [System.Exception] {
        Write-Warning -Message "Unable to append log entry to Add-RightClickRunAs.log file"
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


function Test-RegistryKeyValue
{
    <#
    .SYNOPSIS
    Tests if a registry value exists.

    .DESCRIPTION
    The usual ways for checking if a registry value exists don't handle when a value simply has an empty or null value.  This function actually checks if a key has a value with a given name.

    .EXAMPLE
    Test-RegistryKeyValue -Path 'hklm:\Software\Carbon\Test' -Name 'Title'

    Returns `True` if `hklm:\Software\Carbon\Test` contains a value named 'Title'.  `False` otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the registry key where the value should be set.  Will be created if it doesn't exist.
        $Path,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the value being set.
        $Name
    )

    if( -not (Test-Path -Path $Path -PathType Container) )
    {
        return $false
    }

    $properties = Get-ItemProperty -Path $Path 
    if( -not $properties )
    {
        return $false
    }

    $member = Get-Member -InputObject $properties -Name $Name
    if( $member )
    {
        return $true
    }
    else
    {
        return $false
    }

}


#################################################################################################################################
# Add "Run as a different User" to right click context menu
if(-not (Test-Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer"))
    {
    Write-LogEntry "Creating Explorer registry item"
    New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\" -Name "Explorer"
    }

if (!(Test-RegistryKeyValue -Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer" -Name "ShowRunasDifferentuserinStart")) 
    {
    Write-LogEntry "Creating ShowRunasDifferentuserinStart registry property"
    New-ItemProperty -Force -Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer" -Name "ShowRunasDifferentuserinStart" -PropertyType dword -Value "00000001"
    }
else
    {
    Write-LogEntry "Setting ShowRunasDifferentuserinStart registry property"
    Set-ItemProperty -Force -Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer" -Name "ShowRunasDifferentuserinStart" -Type dword -Value "00000001"
    }
#################################################################################################################################
