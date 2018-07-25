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




#################################################################################################################################
# Support Information
copy-item -Force $ScriptPath\oemlogo.bmp "$WINDIR\system32\oemlogo.bmp"

$manufacturer = $cs.Manufacturer
$model = $cs.Model

if(-not (Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\OEMInformation"))
    {
    New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion" -Name "OEMInformation"
    }

New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\OEMInformation" -Name Logo -PropertyType String -Value "%systemroot%\system32\OEMLogo.bmp" -Force
New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\OEMInformation" -Name Manufacturer -PropertyType String -Value "$manufacturer" -Force
New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\OEMInformation" -Name Model -PropertyType String -Value "$model" -Force
New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\OEMInformation" -Name SupportPhone -PropertyType String -Value "(555) 867-5309 -Force
#################################################################################################################################

stop-transcript
