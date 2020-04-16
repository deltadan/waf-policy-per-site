# Install IIS
$publicSettings = @{ "fileUris" = (, "https://raw.githubusercontent.com/Azure/azure-docs-powershell-samples/master/application-gateway/iis/appgatewayurl.ps1"); 
    "commandToExecute"          = "powershell -ExecutionPolicy Unrestricted -File appgatewayurl.ps1" 
}

$vmss = Get-AzVmss -ResourceGroupName myResourceGroupAG -VMScaleSetName myvmss

Add-AzVmssExtension -VirtualMachineScaleSet $vmss `
    -Name "customScript" `
    -Publisher "Microsoft.Compute" `
    -Type "CustomScriptExtension" `
    -TypeHandlerVersion 1.8 `
    -Setting $publicSettings

Update-AzVmss `
    -ResourceGroupName myResourceGroupAG `
    -Name myvmss `
    -VirtualMachineScaleSet $vmss

# Create Storage Acct
$storageAccount = New-AzStorageAccount `
    -ResourceGroupName myResourceGroupAG `
    -Name myagstore1 `
    -Location eastus `
    -SkuName "Standard_LRS"

# Configure Diagnostics
$appgw = Get-AzApplicationGateway `
    -ResourceGroupName myResourceGroupAG `
    -Name myAppGateway

$store = Get-AzStorageAccount `
    -ResourceGroupName myResourceGroupAG `
    -Name myagstore1

Set-AzDiagnosticSetting `
    -ResourceId $appgw.Id `
    -StorageAccountId $store.Id `
    -Categories ApplicationGatewayAccessLog, ApplicationGatewayPerformanceLog, ApplicationGatewayFirewallLog `
    -Enabled $true `
    -RetentionEnabled $true `
    -RetentionInDays 30