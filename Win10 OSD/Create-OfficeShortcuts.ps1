
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

#file paths for 32 bit office
$officeRoot = "C:\Program Files (x86)\Microsoft Office\root\Office16\"
$excelPath = $officeRoot + "excel.exe"
$groovePath = $officeRoot + "groove.exe"
$powerpntPath = $officeRoot + "powerpnt.exe"
$lyncPath = $officeRoot + "lync.exe"
$outlookPath = $officeRoot + "outlook.exe"
$onenotePath = $officeRoot + "onenote.exe"
$winwordPath = $officeRoot + "winword.exe"
$msaccessPath = $officeRoot + "msaccess.exe"

#file paths for 64 bit office
#this root path is a total guess based on the 32 bit
$office64Root = "C:\Program Files\Microsoft Office\root\Office16\"
$excel64Path = $office64Root + "excel.exe"
$groove64Path = $office64Root + "groove.exe"
$powerpnt64Path = $office64Root + "powerpnt.exe"
$lync64Path = $office64Root + "lync.exe"
$outlook64Path = $office64Root + "outlook.exe"
$onenote64Path = $office64Root + "onenote.exe"
$winword64Path = $office64Root + "winword.exe"
$msaccess64Path = $office64Root + "msaccess.exe"


$LyncLnk = "$ALLUSERS\Microsoft\Windows\Start Menu\Programs\Skype for Business 2016.lnk"
$OutlookLnk = "$ALLUSERS\Microsoft\Windows\Start Menu\Programs\Outlook 2016.lnk"
$ExcelLnk = "$ALLUSERS\Microsoft\Windows\Start Menu\Programs\Excel 2016.lnk"


# Create Lync shortcut for the start menu layout
if(!(Test-Path $LyncLnk))
    {
    if(Test-Path $lyncPath)
        {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($LyncLnk)
        $Shortcut.TargetPath = $lyncPath
        $Shortcut.Save()
        }
    elseif (Test-Path $lync64Path)
        {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($LyncLnk)
        $Shortcut.TargetPath = $lync64Path
        $Shortcut.Save()
        }
    else
        {
        write-host "neither $lyncPath or $lync64Path exist"
        }
    }
else
    {
    write-host "$LyncLnk exists"
    }

# Create Outlook shortcut for the start menu layout
if(!(Test-Path $OutlookLnk))
    {
    if(Test-Path $outlookPath)
        {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($OutlookLnk)
        $Shortcut.TargetPath = $outlookPath
        $Shortcut.Save()
        }
    elseif (Test-Path $outlook64Path)
        {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($OutlookLnk)
        $Shortcut.TargetPath = $outlook64Path
        $Shortcut.Save()
        }
    else
        {
        write-host "neither $outlookPath or $outlook64Path exist"
        }
    }
else
    {
    write-host "$OutlookLnk exists"
    }

# Create Excel shortcut for the start menu layout
if(!(Test-Path $ExcelLnk))
    {
    if(Test-Path $excelPath)
        {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ExcelLnk)
        $Shortcut.TargetPath = $excelPath
        $Shortcut.Save()
        }
    elseif (Test-Path $excel64Path)
        {
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ExcelLnk)
        $Shortcut.TargetPath = $excel64Path
        $Shortcut.Save()
        }
    else
        {
        write-host "neither $excelPath or $excel64Path exist"
        }
    }
else
    {
    write-host "$ExcelLnk exists"
    }

Stop-Transcript
