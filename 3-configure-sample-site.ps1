# Install IIS
$publicSettings = @{ "fileUris" = (, "https://raw.githubusercontent.com/Azure/azure-docs-powershell-samples/master/application-gateway/iis/appgatewayurl.ps1"); 
    "commandToExecute"          = "powershell -ExecutionPolicy Unrestricted -File appgatewayurl.ps1" 
}

$vmss = Get-AzVmss -ResourceGroupName myResourceGroup4AG -VMScaleSetName myvmss

Add-AzVmssExtension -VirtualMachineScaleSet $vmss `
    -Name "customScript" `
    -Publisher "Microsoft.Compute" `
    -Type "CustomScriptExtension" `
    -TypeHandlerVersion 1.8 `
    -Setting $publicSettings

Update-AzVmss `
    -ResourceGroupName myResourceGroup4AG `
    -Name myvmss `
    -VirtualMachineScaleSet $vmss

# Create Storage Acct
$storageAccount = New-AzStorageAccount `
    -ResourceGroupName myResourceGroup4AG `
    -Name myagstore1 `
    -Location eastus `
    -SkuName "Standard_LRS"

# Configure Diagnostics
$appgw = Get-AzApplicationGateway `
    -ResourceGroupName myResourceGroup4AG `
    -Name myAppGateway

$store = Get-AzStorageAccount `
    -ResourceGroupName myResourceGroup4AG `
    -Name myagstore1

Set-AzDiagnosticSetting `
    -ResourceId $appgw.Id `
    -StorageAccountId $store.Id `
    -Categories ApplicationGatewayAccessLog, ApplicationGatewayPerformanceLog, ApplicationGatewayFirewallLog `
    -Enabled $true `
    -RetentionEnabled $true `
    -RetentionInDays 30