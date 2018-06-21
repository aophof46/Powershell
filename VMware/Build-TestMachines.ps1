param (
	[string]$Environment = "Prod",
    	[string]$Quantity = "4",
    	[string]$Name = "My Name"
	)

# Prod details
$ProdSrv = "prodserver.domain.com"
$ProdTemplate = "Prod_Template"
$ProdBootDisk =  "[Datastore] Bootdisks/Prod_Boot.iso"

# Int details
$IntSrv = "prodserver.domain.com"
$IntTemplate = "Int_Template"
$IntBootDisk = "[Datastore] Bootdisks/Lab_Boot.iso"

# VM Config - not needed since we use a template
$VMDiskGB = "80" 
$VMMemoryGB = "4" 
$VMNumCpu = "2" 
$VMNetworkName = "VLAN40"

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


if($Environment -eq "Int")
    {
    $vSphereSrv = $IntSrv
    $TemplateName = $IntTemplate
    $BootDisk = $IntBootDisk
    }
elseif($Environment -eq "Prod")
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


# Remove backslash from Domain\username so username can be used in the VM name
if($($credentials.username) -match '\\')
    {
    $UserName = $($($credentials.username).split('\'))[1]
    }
else
    {
    $UserName = $Credentials.UserName
    }


# Disable CEIP participation dialog
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$False
# MacOS barks if this is missing
Set-PowerCLIConfiguration -InvalidCertificateAction ignore -confirm:$false -Scope User 
# Connect to vSphere
Connect-VIServer -server $vSphereSrv -Protocol https -Credential $Credentials

#Check if Template exists
$Win10Template = get-template -Name $TemplateName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
if(!($Win10Template))
    {
    write-host "Specified Template was not found"
    exit
    }

$vmWareCluster = Get-Cluster
$storageCluster = get-datastorecluster


for ($i = 1; $i -le $Quantity; $i++)
    {
    # Check if template exists

    $TempVMName = "$DateStamp - $Environment - $UserName $i"
    write-host "VM Name: $TempVMName"
    if(get-VM -Name $TempVMName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue)
        {
        write-host "$TempVMName already exists"
        }
    else
        {
                # Create VM
        New-VM -Name $TempVMName -Template $Win10Template -ResourcePool $vmWareCluster -Datastore $storageCluster -Location $Name
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

    
