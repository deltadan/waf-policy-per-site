# Configure Network Elements for VMSS
$vnet = Get-AzVirtualNetwork `
    -ResourceGroupName myResourceGroup4AG `
    -Name myVNet

$appgw = Get-AzApplicationGateway `
    -ResourceGroupName myResourceGroup4AG `
    -Name myAppGateway

$backendPool = Get-AzApplicationGatewayBackendAddressPool `
    -Name appGatewayBackendPool `
    -ApplicationGateway $appgw

# Configure Network Elements for VMSS
$ipConfig = New-AzVmssIpConfig `
    -Name myVmssIPConfig `
    -SubnetId $vnet.Subnets[0].Id `
    -ApplicationGatewayBackendAddressPoolsId $backendPool.Id

# Create VM Scale Sets
$vmssConfig = New-AzVmssConfig `
    -Location eastus `
    -SkuCapacity 2 `
    -SkuName Standard_DS2 `
    -UpgradePolicyMode Automatic

Set-AzVmssStorageProfile $vmssConfig `
    -ImageReferencePublisher MicrosoftWindowsServer `
    -ImageReferenceOffer WindowsServer `
    -ImageReferenceSku 2016-Datacenter `
    -ImageReferenceVersion latest `
    -OsDiskCreateOption FromImage

Set-AzVmssOsProfile $vmssConfig `
    -AdminUsername azureuser `
    -AdminPassword "Azure123456!" `
    -ComputerNamePrefix myvmss

Add-AzVmssNetworkInterfaceConfiguration `
    -VirtualMachineScaleSet $vmssConfig `
    -Name myVmssNetConfig `
    -Primary $true `
    -IPConfiguration $ipConfig

New-AzVmss `
    -ResourceGroupName myResourceGroup4AG `
    -Name myvmss `
    -VirtualMachineScaleSet $vmssConfig