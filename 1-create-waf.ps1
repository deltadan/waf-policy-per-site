#Create a resource group
$rgname = New-AzResourceGroup -Name myResourceGroup4AG -Location eastus

#Create network resources
$backendSubnetConfig = New-AzVirtualNetworkSubnetConfig `
    -Name myBackendSubnet `
    -AddressPrefix 10.0.1.0/24

$agSubnetConfig = New-AzVirtualNetworkSubnetConfig `
    -Name myAGSubnet `
    -AddressPrefix 10.0.2.0/24

$vnet = New-AzVirtualNetwork `
    -ResourceGroupName myResourceGroup4AG `
    -Location eastus `
    -Name myVNet `
    -AddressPrefix 10.0.0.0/16 `
    -Subnet $backendSubnetConfig, $agSubnetConfig

$pip = New-AzPublicIpAddress `
    -ResourceGroupName myResourceGroup4AG `
    -Location eastus `
    -Name myAGPublicIPAddress `
    -AllocationMethod Static `
    -Sku Standard

#Create an application gateway
$vnet = Get-AzVirtualNetwork `
    -ResourceGroupName myResourceGroup4AG `
    -Name myVNet

$subnet = $vnet.Subnets[1]

$gipconfig = New-AzApplicationGatewayIPConfiguration `
    -Name myAGIPConfig `
    -Subnet $subnet

$fipconfig = New-AzApplicationGatewayFrontendIPConfig `
    -Name myAGFrontendIPConfig `
    -PublicIPAddress $pip

$frontendport80 = New-AzApplicationGatewayFrontendPort `
    -Name myFrontendPort `
    -Port 80
  
$frontendport8080 = New-AzApplicationGatewayFrontendPort `
    -Name myFrontendPort8080 `
    -Port 8080

#Create the backend pool and settings
$defaultPool = New-AzApplicationGatewayBackendAddressPool `
    -Name appGatewayBackendPool 

$poolSettings = New-AzApplicationGatewayBackendHttpSettings `
    -Name myPoolSettings `
    -Port 80 `
    -Protocol Http `
    -CookieBasedAffinity Enabled `
    -RequestTimeout 120

#Create two WAF policies
$variable = New-AzApplicationGatewayFirewallMatchVariable -VariableName RequestUri
$condition = New-AzApplicationGatewayFirewallCondition -MatchVariable $variable -Operator Contains -MatchValue "globalAllow" 
$rule = New-AzApplicationGatewayFirewallCustomRule -Name globalAllow -Priority 5 -RuleType MatchRule -MatchCondition $condition -Action Allow

$variable1 = New-AzApplicationGatewayFirewallMatchVariable -VariableName RequestUri
$condition1 = New-AzApplicationGatewayFirewallCondition -MatchVariable $variable1 -Operator Contains -MatchValue "globalBlock" 
$rule1 = New-AzApplicationGatewayFirewallCustomRule -Name globalAllow -Priority 10 -RuleType MatchRule -MatchCondition $condition1 -Action Block

$variable2 = New-AzApplicationGatewayFirewallMatchVariable -VariableName RequestUri
$condition2 = New-AzApplicationGatewayFirewallCondition -MatchVariable $variable2 -Operator Contains -MatchValue "siteAllow" 
$rule2 = New-AzApplicationGatewayFirewallCustomRule -Name globalAllow -Priority 5 -RuleType MatchRule -MatchCondition $condition2 -Action Allow

$variable3 = New-AzApplicationGatewayFirewallMatchVariable -VariableName RequestUri
$condition3 = New-AzApplicationGatewayFirewallCondition -MatchVariable $variable3 -Operator Contains -MatchValue "siteBlock" 
$rule3 = New-AzApplicationGatewayFirewallCustomRule -Name globalAllow -Priority 10 -RuleType MatchRule -MatchCondition $condition3 -Action Block

$variable4 = New-AzApplicationGatewayFirewallMatchVariable -VariableName RequestUri
$condition4 = New-AzApplicationGatewayFirewallCondition -MatchVariable $variable4 -Operator Contains -MatchValue "URIAllow" 
$rule4 = New-AzApplicationGatewayFirewallCustomRule -Name globalAllow -Priority 5 -RuleType MatchRule -MatchCondition $condition4 -Action Allow

$variable5 = New-AzApplicationGatewayFirewallMatchVariable -VariableName RequestUri
$condition5 = New-AzApplicationGatewayFirewallCondition -MatchVariable $variable5 -Operator Contains -MatchValue "URIBlock" 
$rule5 = New-AzApplicationGatewayFirewallCustomRule -Name globalAllow -Priority 10 -RuleType MatchRule -MatchCondition $condition5 -Action Block

$policySettingGlobal = New-AzApplicationGatewayFirewallPolicySetting `
    -Mode Prevention `
    -State Enabled `
    -MaxRequestBodySizeInKb 100 `
    -MaxFileUploadInMb 256

$wafPolicyGlobal = New-AzApplicationGatewayFirewallPolicy `
    -Name wafpolicyGlobal `
    -ResourceGroup myResourceGroup4AG `
    -Location eastus `
    -PolicySetting $PolicySettingGlobal `
    -CustomRule $rule, $rule1

$policySettingSite = New-AzApplicationGatewayFirewallPolicySetting `
    -Mode Prevention `
    -State Enabled `
    -MaxRequestBodySizeInKb 100 `
    -MaxFileUploadInMb 5

$wafPolicySite = New-AzApplicationGatewayFirewallPolicy `
    -Name wafpolicySite `
    -ResourceGroup myResourceGroup4AG `
    -Location eastus `
    -PolicySetting $PolicySettingSite `
    -CustomRule $rule2, $rule3

#Create the default listener and rule
$globalListener = New-AzApplicationGatewayHttpListener `
    -Name mydefaultListener `
    -Protocol Http `
    -FrontendIPConfiguration $fipconfig `
    -FrontendPort $frontendport80

$frontendRule = New-AzApplicationGatewayRequestRoutingRule `
    -Name rule1 `
    -RuleType Basic `
    -HttpListener $globallistener `
    -BackendAddressPool $defaultPool `
    -BackendHttpSettings $poolSettings
  
$siteListener = New-AzApplicationGatewayHttpListener `
    -Name siteListener `
    -Protocol Http `
    -FrontendIPConfiguration $fipconfig `
    -FrontendPort $frontendport8080 `
    -FirewallPolicy $wafPolicySite
  
$frontendRuleSite = New-AzApplicationGatewayRequestRoutingRule `
    -Name rule2 `
    -RuleType Basic `
    -HttpListener $siteListener `
    -BackendAddressPool $defaultPool `
    -BackendHttpSettings $poolSettings

#Create the application gateway with the WAF
$sku = New-AzApplicationGatewaySku `
    -Name WAF_v2 `
    -Tier WAF_v2 `
    -Capacity 2

$appgw = New-AzApplicationGateway `
    -Name myAppGateway `
    -ResourceGroupName myResourceGroup4AG `
    -Location eastus `
    -BackendAddressPools $defaultPool `
    -BackendHttpSettingsCollection $poolSettings `
    -FrontendIpConfigurations $fipconfig `
    -GatewayIpConfigurations $gipconfig `
    -FrontendPorts $frontendport80, $frontendport8080 `
    -HttpListeners $globallistener, $siteListener `
    -RequestRoutingRules $frontendRule `
    -Sku $sku `
    -FirewallPolicy $wafPolicyGlobal

#Apply a per-URI policy
$policySettingURI = New-AzApplicationGatewayFirewallPolicySetting `
    -Mode Prevention `
    -State Enabled `
    -MaxRequestBodySizeInKb 100 `
    -MaxFileUploadInMb 5

$wafPolicyURI = New-AzApplicationGatewayFirewallPolicy `
    -Name wafpolicySite `
    -ResourceGroup myResourceGroup4AG `
    -Location eastus `
    -PolicySetting $PolicySettingURI `
    -CustomRule $rule4, $rule5

## added RG to this command
$Gateway = Get-AzApplicationGateway -Name "myAppGateway" -ResourceGroupName myResourceGroup4AG

$PathRuleConfig = New-AzApplicationGatewayPathRuleConfig -Name "base" `
    -Paths "/base" `
    -BackendAddressPool $defaultPool `
    -BackendHttpSettings $poolSettings `
    -FirewallPolicy $wafPolicyURI

$PathRuleConfig1 = New-AzApplicationGatewayPathRuleConfig `
    -Name "test" -Paths "/test" `
    -BackendAddressPool $defaultPool `
    -BackendHttpSettings $poolSettings

$Gateway = Get-AzApplicationGateway -ResourceGroupName myResourceGroup4AG -Name myAppGateway

$URLPathMap = Add-AzApplicationGatewayUrlPathMapConfig -Name "PathMap" `
    -PathRules $PathRuleConfig, $PathRuleConfig1 `
    -DefaultBackendAddressPoolId $defaultPool.Id `
    -DefaultBackendHttpSettingsId $poolSettings.Id `
    -ApplicationGateway $Gateway

Set-AzApplicationGateway -ApplicationGateway $Gateway
$Gateway = Get-AzApplicationGateway -ResourceGroupName myResourceGroup4AG -Name myAppGateway

$URLPathMap = Get-AzApplicationGatewayUrlPathMapConfig -Name PathMap -ApplicationGateway $Gateway
$Gateway = Add-AzApplicationGatewayRequestRoutingRule -ApplicationGateway $Gateway `
    -Name "RequestRoutingRule" `
    -RuleType PathBasedRouting `
    -HttpListener $siteListener `
    -UrlPathMap $URLPathMap`
-Verbose

Set-AzApplicationGateway -ApplicationGateway $Gateway
