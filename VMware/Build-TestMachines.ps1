param (
	[string]$Environment = "Prod",
    [string]$Quantity = "1",
    [string]$Type = "Build"
	)
	
# vSphere Servers
$ProdSrv = "PRODUCTION_VCENTER"
$LabSrv = "LAB_VCENTER"

# Bootdisk details
$BuildBootDisk = "[NAME_OF_DATASTORE] DATASTORE_FOLDER/MDT_BUILD_x64.iso"
$LabBootDisk = "[NAME_OF_DATASTORE] DATASTORE_FOLDER/MDT_LAB_x64.iso"
$ProdBootDisk = "[NAME_OF_DATASTORE] DATASTORE_FOLDER/MDT_PROD_x64.iso"

# VM Config
$VMDiskGB = "80" 
$VMMemoryGB = "4" 
$VMNumCpu = "2" 
$VMFolder = "VM_FOLDER_NAME"
$VMDatastore = "VM_DATASTORE_NAME"
$VMNetworkName = "CLIENT_NETWORK_NAME"

$DateStamp = get-date -UFormat %Y%m%d

$OSType = [environment]::OSVersion.Platform
if($OSType -eq "Win32NT") #Windows
    {
    if(!(get-packageprovider -Name "Nuget"))
        {
        Install-PackageProvider -Name NuGet -Force
        }
    if(!(get-module -Name "VMware.VIMAutomation.Cis.Core"))
        {
        Find-Module -Name vmware.powercli -Repository PSGallery | Install-Module
        }
    }
elseif($OSType -eq "Unix") #MacOS
    {
    if(!(Get-Module -Name VMware.PowerCLI -ListAvailable))
        {
        Install-Module -Name VMware.PowerCLI -Scope CurrentUser -Force
        }
    }

$Credentials = get-credential
if(!($Credentials))
    {
    write-host "no credentials found... exiting"
    exit
    }

# Type of machine (determine which bootdisk to use)
if($Type -eq "Lab")
    {
    $BootDisk =  $LabBootDisk 
    }
elseif($Type -eq "Prod")
    {
    $BootDisk =  $ProdBootDisk
    }
else
    {
    $BootDisk =  $BuildBootDisk
    }

# Environment (determine which vSphere server to use)
if($Environment -eq "Lab")
    {
    $vSphereSrv = $LabSrv
    }
elseif($Environment -eq "Prod")
    {
    $vSphereSrv = $ProdSrv
    }
else
    {
    write-host "No environment selected"
    exit
    }

# Remove backslash from Domain\username so username can be used in the VM name
if($($credentials.username) -match '\\')
    {
    $UserName = $($($credentials.username).split('\'))[1]
    }
else
    {
    $UserName = $Credentials.UserName
    }

# Get Boot disk name
if($($BootDisk) -match '\/')
    {
    $ISOName = $($($BootDisk).split('/'))[1]
    }
else
    {
    $ISOName = $BootDisk
    }

if($($ISOName) -match '.iso')
    {
    $ISOName = $($($ISOName).split('.iso'))[0]
    }



# Disable CEIP participation dialog
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$False
# MacOS barks if this is missing
Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false -Scope User 
# Connect to vSphere
Connect-VIServer -server $vSphereSrv -Protocol https -Credential $Credentials

$vmWareCluster = Get-Cluster
$storageCluster = get-datastorecluster

for ($i = 1; $i -le $Quantity; $i++)
    {
    # Check if template exists

    #$TempVMName = "$DateStamp - $Environment - $UserName $i"
    $TempVMName = $ISOName + "_VM" + $i
    write-host "VM Name: $TempVMName"
    if(get-VM -Name $TempVMName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue)
        {
        write-host "$TempVMName already exists"
        }
    else
        {
                # Create VM
        New-VM -Name $TempVMName -GuestId windows7_64Guest -ResourcePool $vmWareCluster -Datastore $VMDatastore -Location $VMFolder -DiskGB $VMDiskGB -MemoryGB $VMMemoryGB -NumCpu $VMNumCpu -NetworkName $VMNetworkName -Notes "$Datestamp - Automated build of $ISOName"
        
        $TempNewVM = get-vm $TempVMName

        # Configure Network adapter as E100e (winpe driver support reasons)
        set-networkadapter -NetworkAdapter $(Get-NetworkAdapter $TempNewVM) -Type e1000e -Confirm:$false

        # Configure CD Drive with ISO
        if(Get-CDDrive -VM $TempNewVM)
            {        
            Get-CDDrive -VM $TempNewVM | Remove-CDDrive -Confirm:$false
            }

        $CDConf = New-CDDrive -VM $TempNewVM -ISOPath $BootDisk -Confirm:$false
        Set-CDDrive -CD $CDConf -StartConnected $True -Confirm:$false

        # Power VM on
        Start-VM -VM $TempNewVM
        
        }
    }
