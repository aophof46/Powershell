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
# Modifiy start menu to pin IE icon and office apps if they have been installed previously in the task sequence
# this should place generate a file called $fileName located in $filePath

# Groove.exe is the old onedrive client, which has since been replaced by the next gen sync client (NGSC).  I've left it in here,
# but we should not be installing it with the Office bits anymore

$fileName = "LayoutModification.xml"
$filePath = "$SYSDRIVE\Users\Default\AppData\Local\Microsoft\Windows\Shell\"
#$filePath = "$env:Userprofile\Desktop\"
$LayoutModFile = $filePath + $fileName



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

#file paths for Internet Explorer
$iePath = "$PROGRAMFILES\Internet Explorer\iexplore.exe"
$ie64Path = "FALSE"
$ieLnk = "$ALLUSERS\Microsoft\Windows\Start Menu\Programs\Accessories\Internet Explorer.lnk"

#file paths for System Center
$scPath = "C:\Windows\CCM\ClientUX\SCClient.exe"
$sc64Path = "FALSE"
$scLnk = "$ALLUSERS\Microsoft\Windows\Start Menu\Programs\Microsoft System Center\Configuration Manager\Software Center.lnk"


# Check to see if LayoutModFile already exists.  If it does, exit.
if(Test-Path $LayoutModFile)
    { 
    Write-Host $LayoutModfile "exists!"
    #exit
    }


#XML file items
$xmlSC = @'
          <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft System Center\Configuration Manager\Software Center.lnk"/>
'@
$xmlIE = @'
          <start:DesktopApplicationTile Size="2x2" Column="2" Row="0" DesktopApplicationLinkPath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Accessories\Internet Explorer.lnk"/>
'@
$xmlExcel = @'
          <start:DesktopApplicationTile Size="2x2" Column="0" Row="2" DesktopApplicationID="Microsoft.Office.EXCEL.EXE.15" /> 
'@
$xmlGroove = @'
          <start:DesktopApplicationTile Size="1x1" Column="5" Row="2" DesktopApplicationID="Microsoft.Office.GROOVE.EXE.15" /> 
'@
$xmlPowerpnt = @'
          <start:DesktopApplicationTile Size="2x2" Column="4" Row="0" DesktopApplicationID="Microsoft.Office.POWERPNT.EXE.15" /> 
'@
$xmlLync = @'
          <start:DesktopApplicationTile Size="2x2" Column="2" Row="0" DesktopApplicationID="Microsoft.Office.lync.exe.15" /> 
'@
$xmlOutlook = @'
          <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationID="Microsoft.Office.OUTLOOK.EXE.15" /> 
'@
$xmlOnenote = @'
          <start:DesktopApplicationTile Size="1x1" Column="4" Row="3" DesktopApplicationID="Microsoft.Office.ONENOTE.EXE.15" /> 
'@
$xmlWinword = @'
          <start:DesktopApplicationTile Size="2x2" Column="2" Row="2" DesktopApplicationID="Microsoft.Office.WINWORD.EXE.15" /> 
'@
$xmlMsaccess = @'
          <start:DesktopApplicationTile Size="1x1" Column="4" Row="2" DesktopApplicationID="Microsoft.Office.MSACCESS.EXE.15" /> 
'@

# MFU = Most Frequently Used, this can be used to populate the top left "Most Used" section of the start menu.
# A maximum of three can be pre-selected.
# Note: These shortcuts must be copied over in advance for these to work, which is done below.
# Note: I chose Lync, Outlook and Excel because those seem to be frequently used items.  Any Office 
#       existing on the local system could probably be used.

$xmlMfuLync = @'
    <DesktopApplicationTile LinkFilePath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Skype for Business 2016.lnk" />
'@
$xmlMfuOutlook = @'
    <DesktopApplicationTile LinkFilePath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Outlook 2016.lnk" />
'@
$xmlMfuExcel = @'
    <DesktopApplicationTile LinkFilePath="%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Excel 2016.lnk" />
'@


#####################################################
#Begin building the XML file
$xmlHeaderText = @'
<LayoutModificationTemplate
	Version="1"
	xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"
	xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
    xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout">
'@
$xmlHeaderText | Out-File $LayoutModFile

#Begin Default Layout Override
$xmlDefaultLayoutOverrideHeaderText = @'
  <DefaultLayoutOverride>
    <StartLayoutCollection>
      <defaultlayout:StartLayout GroupCellWidth="6">
'@
$xmlDefaultLayoutOverrideHeaderText | Out-File $LayoutModFile -Append

#####################################################
#Begin First Start group
$xmlFirstStartGroupHeaderText = @'
        <start:Group Name="">
'@
$xmlFirstStartGroupHeaderText | Out-File $LayoutModFile -Append

#If the Support Center and IE shortcuts were created, add them to the start menu
if(Test-Path $scLnk)
    { $xmlSC | Out-File $LayoutModFile -Append }

if(Test-Path $ieLnk)
    { $xmlIE | Out-File $LayoutModFile -Append }

$xmlFirstStartGroupFooterText = @'
        </start:Group>
'@
$xmlFirstStartGroupFooterText | Out-File $LayoutModFile -Append
#End of First Start Group
#####################################################


#####################################################
#Begin Second Start group - this will only add to the 
#XML file if office (specifically Word) is present.
#If word is not present, this group does not get created.
if((Test-Path $winwordPath) -or (Test-Path $winword64Path))
    {
    $xmlSecondStartGroupHeaderText = @'
        <start:Group Name="Office 2016">
'@
    $xmlSecondStartGroupHeaderText | Out-File $LayoutModFile -Append

    if((Test-Path $excelPath) -or (Test-Path $excel64Path))
        { $xmlExcel | Out-File $LayoutModFile -Append }
    if((Test-Path $groovePath) -or (Test-Path $groove64Path))
        { $xmlGroove | Out-File $LayoutModFile -Append }
    if((Test-Path $powerpntPath) -or (Test-Path $powerpnt64Path))
        { $xmlPowerpnt | Out-File $LayoutModFile -Append }
    if((Test-Path $lyncPath) -or (Test-Path $lync64Path))
        { $xmlLync | Out-File $LayoutModFile -Append }
    if((Test-Path $outlookPath) -or (Test-Path $outlook64Path))
        { $xmlOutlook | Out-File $LayoutModFile -Append }
    if((Test-Path $onenotePath) -or (Test-Path $onenote64Path))
        { $xmlOnenote | Out-File $LayoutModFile -Append }
    if((Test-Path $winwordPath) -or (Test-Path $winword64Path))
        { $xmlWinword | Out-File $LayoutModFile -Append }
    if((Test-Path $msaccessPath) -or (Test-Path $msaccess64Path))
        { $xmlMsaccess | Out-File $LayoutModFile -Append }

    $xmlSecondStartGroupFooterText = @'
        </start:Group>
'@
    $xmlSecondStartGroupFooterText | Out-File $LayoutModFile -Append
    }
#End of Second Start Group
#####################################################


$xmlDefaultLayoutOverrideFooterText = @'
      </defaultlayout:StartLayout>
    </StartLayoutCollection>
  </DefaultLayoutOverride>
'@
$xmlDefaultLayoutOverrideFooterText | Out-File $LayoutModFile -Append
#End Default Layout Override




#####################################################
#Begin MFU Apps - this will only add to the 
#XML file if office (specifically Word) is present.
#If desired, an else portion of the loop can be created
#to add most frequently used items when office is not
#present
if((Test-Path $winwordPath) -or (Test-Path $winword64Path))
    {
    $xmlMFUHeaderText = @'
  <TopMFUApps>
'@
    $xmlMFUHeaderText | Out-File $LayoutModFile -Append

    if(((Test-Path $lyncPath) -or (Test-Path $lync64Path)) -and (Test-Path $xmlMfuLyncLnk))
        { $xmlMfuLync | Out-File $LayoutModFile -Append }
    if(((Test-Path $outlookPath) -or (Test-Path $outlook64Path)) -and (Test-Path $xmlMfuOutlookLnk))
        { $xmlMfuOutlook | Out-File $LayoutModFile -Append }
    if(((Test-Path $excelPath) -or (Test-Path $excel64Path)) -and (Test-Path $xmlMfuExcelLnk))
        { $xmlMfuExcel | Out-File $LayoutModFile -Append }

    $xmlMFUFooterText = @'
  </TopMFUApps>
'@
    $xmlMFUFooterText | Out-File $LayoutModFile -Append
    }   
#End MFU Apps
#####################################################


$xmlXMLFooterText = @'
</LayoutModificationTemplate>
'@
$xmlXMLFooterText | Out-File $LayoutModFile -Append
#End of the XML File
#################################################################################################################################

stop-transcript
