
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

# taken from https://github.com/W4RH4WK/Debloat-Windows-10
Import-Module -DisableNameChecking $ScriptPath\take-own.psm1

# other debloat suggestions https://blog.danic.net/?p=5
	
# Elevating prviledges for this process"
do {} until (Elevate-Privileges SeTakeOwnershipPrivilege)


$apps = @(
    # default Windows 10 apps
    "Microsoft.3DBuilder"
    "Microsoft.Appconnector"
    #"Microsoft.BingFinance"
    #"Microsoft.BingNews"
    #"Microsoft.BingSports"
    #"Microsoft.BingWeather"
    "Microsoft.Getstarted"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.Office.OneNote"
    "Microsoft.Office.Sway"
    "Microsoft.People"
    "Microsoft.SkypeApp"
    #"Microsoft.Windows.Photos"
    #"Microsoft.WindowsAlarms"
    #"Microsoft.WindowsCalculator"
    #"Microsoft.WindowsCamera"
    #"Microsoft.WindowsMaps"
    "Microsoft.WindowsPhone"
    #"Microsoft.WindowsSoundRecorder"
    #"Microsoft.WindowsStore"
    "Microsoft.XboxApp"
    #"Microsoft.ZuneMusic"
    #"Microsoft.ZuneVideo"
    "microsoft.windowscommunicationsapps"
    "Microsoft.MinecraftUWP"
    "Microsoft.OneConnect"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.Messaging"
	



    # non-Microsoft
    "9E2F88E3.Twitter"
    "Flipboard.Flipboard"
    "ShazamEntertainmentLtd.Shazam"
    "king.com.CandyCrushSaga"
    "ClearChannelRadioDigital.iHeartRadio"

    # apps which cannot be removed using Remove-AppxPackage
    #"Microsoft.BioEnrollment"
    #"Microsoft.MicrosoftEdge"
    #"Microsoft.Windows.Cortana"
    "Microsoft.WindowsFeedback"
    #"Microsoft.XboxGameCallableUI"
    #"Microsoft.XboxIdentityProvider"
    #"Windows.ContactSupport"
)

<#
foreach ($app in $apps) {
    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage

    Get-AppXProvisionedPackage -Online |
        where DisplayName -EQ $app |
        Remove-AppxProvisionedPackage -Online
}
#>

foreach ($app in $apps) {   

    $appxLocation = (get-appxpackage -AllUsers -Name $app).InstallLocation
    if($appxLocation)
        { 
        $manifestPath = "$($appxLocation)\AppxManifest.xml" 
        Write-Host "Running command - Add-AppxPackage -Path $manifestPath -Register -DisableDevelopmentMode"
        Add-AppxPackage -Path $manifestPath -Register -DisableDevelopmentMode
        Write-Host "Running command - Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage"
        Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage
        }
    Else
        {
        Write-Host "$app - no location found"
        }
    
    
    $packageName = (Get-AppXProvisionedPackage -Online | where DisplayName -EQ $app).PackageName
    if($packageName)
        {
        Write-Host "Running Command - Get-AppXProvisionedPackage -Online | where DisplayName -EQ $app | Remove-AppxProvisionedPackage -Online"
        Get-AppXProvisionedPackage -Online | where DisplayName -EQ $app | Remove-AppxProvisionedPackage -Online   
        }
    else
        {
        Write-Host "$app - no appx provisioned package found"
        }
        
    #$appPath="$Env:LOCALAPPDATA\Packages\$app*"
    #Remove-Item $appPath -Recurse -Force -ErrorAction 0
}

# Force removing system apps
$needles = @(

    #"Anytime"
    #"PPIProjection"
    #"BioEnrollment"
    #"Browser"
    "ContactSupport"
    #"Cortana"       # This will disable startmenu search.
    #"Defender"
    "Feedback"
    #"Flash"
    #"Gaming"
    #"InternetExplorer"
    #"Maps"
    #"OneDrive"
    #"Wallet"
    #"Xbox"
    #"OneConnect"
    #"Holographic"
)

foreach ($needle in $needles) {
    $pkgs = (ls "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages" |
        where Name -Like "*$needle*")

    foreach ($pkg in $pkgs) {

        $pkgname = $pkg.Name.split('\')[-1]
        write-host $pkgname
        Takeown-Registry($pkg.Name)
        Takeown-Registry($pkg.Name + "\Owners")

        Set-ItemProperty -Path ("HKLM:" + $pkg.Name.Substring(18)) -Name Visibility -Value 1
        New-ItemProperty -Path ("HKLM:" + $pkg.Name.Substring(18)) -Name DefVis -PropertyType DWord -Value 2
        Remove-Item      -Path ("HKLM:" + $pkg.Name.Substring(18) + "\Owners")

        dism.exe /Online /Remove-Package /PackageName:$pkgname /NoRestart
    }
}

Stop-Transcript
