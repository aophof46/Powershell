#Set initial variables
$ScriptName = split-path $MyInvocation.InvocationName -Leaf
if(!($ScriptName))
    {
    $ScriptName = "Unnamed"
    }
$TranscriptName = "C:\Windows\Temp\" + $ScriptName + ".txt"
	
Start-Transcript -path $TranscriptName -noClobber -append
$ScriptPath = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
$WINDIR=$env:WINDIR
$PROGRAMFILES=$env:ProgramW6432
$ALLUSERS = $env:ALLUSERSPROFILE
$SYSDRIVE = $env:SystemDrive
$OSversion = [System.Environment]::OSVersion.Version.Build
$date=Get-Date -format M-d-yy
$cs = Get-WmiObject -Class Win32_ComputerSystem


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
    New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\" -Name "Explorer"
    }

if (!(Test-RegistryKeyValue -Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer" -Name "ShowRunasDifferentuserinStart")) 
    {
    New-ItemProperty -Force -Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer" -Name "ShowRunasDifferentuserinStart" -PropertyType dword -Value "00000001"
    }
else
    {
    Set-ItemProperty -Force -Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer" -Name "ShowRunasDifferentuserinStart" -Type dword -Value "00000001"
    }
#################################################################################################################################

stop-transcript
