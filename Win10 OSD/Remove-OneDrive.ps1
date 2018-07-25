
#Set initial variables
$ScriptName = split-path $MyInvocation.InvocationName -Leaf
if(!($ScriptName))
    {
    $ScriptName = "Unnamed"
    }
$TranscriptName = "C:\Windows\Temp\" + $ScriptName + ".txt"
	
Start-Transcript -path $TranscriptName -noClobber -append
#$ScriptPath = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
$WINDIR=$env:WINDIR
$PROGRAMFILES=$env:ProgramW6432
$ALLUSERS = $env:ALLUSERSPROFILE
$SYSDRIVE = $env:SystemDrive
$OSversion = [System.Environment]::OSVersion.Version.Build
$date=Get-Date -format M-d-yy
$cs = Get-WmiObject -Class Win32_ComputerSystem


#################################################################################################################################
# This section will modify the registry so that the "Onedrive - Personal" folder is not pinned to the Explorer window
# Mount HKEY_CLASSES_ROOT as it is not already built in
if(!(Test-Path "HKCR:"))
    {
      new-psdrive -psProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR
    }

# Registry paths for Onedrive Personal start menu keys
$Paths = "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}", "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" 

# Name of registry entry
$Name = "System.IsPinnedToNameSpaceTree"

# Set Value to 1 to pin in Onedrive personal to the start menu
# Set Value to 0 to unpin Onedrive personal from the start menu
$value = "0"

foreach($Registrypath in $Paths)
    {
      IF(!(Test-Path $registryPath))
        {

            New-Item -Path $registryPath -Force | Out-Null
            New-ItemProperty -Force -Path $registryPath -Name $name -PropertyType DWORD -Value $value 
        }

      ELSE 
        {
        set-ItemProperty -Force -Path $registryPath -Name $name -Value $value -Type DWord 
        }
    }


# Unmount HKEY_CLASSES_ROOT as we are done with it
if(Test-Path "HKCR:")
    {
      remove-psdrive -psProvider registry -Name HKCR
    }
#################################################################################################################################

Stop-Transcript
