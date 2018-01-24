
param (
	[string]$Environment = "Prod",
    [string]$Machines = "4"
	)


if(!(get-packageprovider -Name "Nuget"))
    {
    Install-PackageProvider -Name NuGet -Force

    }
if(!(get-module -Name "VMware.VIMAutomation.Cis.Core"))
    {
    Find-Module -Name vmware.powercli -Repository PSGallery | Install-Module
    }

# Disable CEIP participation dialog
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$False

$Credentials = get-credential
if(!($Credentials))
    {
    write-host "no credentials found... exiting"
    exit
    }


# Prod / Int
#$env = "Prod"
#$NumberOfNewVMs = "4"
$env = $environment
$NumberOfNewVMs = $Machines

$vmLocation = "My Name"

# Prod details
$ProdSrv = "prodserver.domain.com"
$ProdTemplate = "Prod_Template"
$ProdBootDisk =  "[VMware_Swing] Bootdisks/Prod_Boot.iso"
# Int details
$IntSrv = "intserver.domain.com"
$IntTemplate = "Int_Template"
$IntBootDisk = "[VMware_Swing] Bootdisks/Int_Boot.iso"

# VM Details -unused
$VMDiskGB = "80" 
$VMMemoryGB = "4" 
$VMNumCpu = "2" 
$VMNetworkName = "VLAN40"

if($env -eq "Int")
    {
    $vSphereSrv = $IntSrv
    $TemplateName = $IntTemplate
    $BootDisk = $IntBootDisk
    }
elseif($env -eq "Prod")
    {
    $vSphereSrv = $ProdSrv
    $TemplateName = $ProdTemplate 
    $BootDisk = $ProdBootDisk
    }
else
    {
    write-host "No environment selected"
    exit
    }


if($($credentials.username) -match '\\')
    {
    $UserName = $($($credentials.username).split('\'))[1]
    }
else
    {
    $UserName = $Credentials.UserName
    }


$DateStamp = get-date -UFormat %Y%m%d
Connect-VIServer -server $vSphereSrv -Protocol https -Credential $Credentials
$Win10Template = get-template -Name $TemplateName
$vmWareCluster = Get-Cluster
$storageCluster = get-datastorecluster


for ($i = 1; $i -le $NumberOfNewVMs; $i++)
    {
    $TempVMName = "$DateStamp - $env - $username $i"
    write-host "VM Name: $TempVMName"
    if(get-VM -Name $TempVMName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue)
        {
        write-host "$TempVMName already exists"
        }
    else
        {

        # Create VM
        New-VM -Name $TempVMName -Template $Win10Template -ResourcePool $vmWareCluster -Datastore $storageCluster -Location $vmLocation 
        $TempNewVM = get-vm $TempVMName


        #  Set first time boot to boot menu
        $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
        $spec.BootOptions = New-Object VMware.Vim.VirtualMachineBootOptions
        $spec.BootOptions.EnterBIOSSetup = $true
        $TempNewVM.ExtensionData.ReconfigVM($spec)



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

    
