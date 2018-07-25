
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

#file paths for Internet Explorer
$iePath = "$PROGRAMFILES\Internet Explorer\iexplore.exe"
$ie64Path = "FALSE"

$ieLnk = "$ALLUSERS\Microsoft\Windows\Start Menu\Programs\Accessories\Internet Explorer.lnk"

# Create IE shortcut 
if(!(Test-Path $ieLnk))
    {
    if(Test-Path $iePath)
        {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ieLnk)
        $Shortcut.TargetPath = $iePath
        $Shortcut.Save()
        }
    elseif (Test-Path $ie64Path)
        {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ieLnk)
        $Shortcut.TargetPath = $ie64Path
        $Shortcut.Save()
        }
    else
        {
        write-host "neither $iePath or $ie64Path exist"
        }
    }
else
    {
    write-host "$ieLnk exists"
    }

Stop-Transcript
