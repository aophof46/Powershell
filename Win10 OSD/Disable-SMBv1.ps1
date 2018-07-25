
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
# This section will disable the SMB 1.0/CIFS File Sharing Support that seems to be enabled by default
#
if (([Environment]::OSVersion.Version -ge (new-object 'Version' 10,0)) -and ((Get-WindowsOptionalFeature -FeatureName SMB1Protocol -Online).state -eq "Enabled" -or "EnablePending"))
    {
      Disable-WindowsOptionalFeature -FeatureName SMB1Protocol -Online -NoRestart
    }
#################################################################################################################################

Stop-Transcript
