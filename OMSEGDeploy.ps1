cls
Select-AzureRmSubscription -SubscriptionName "opsgilitytraining"

$AzureHQLocation = "East US"
$AzureOnPremLocation = "West US"

# Virtual Network Configurations 
$ContosoDNSIP = "10.6.0.4"

$ContosoAzureVNETName = "ContosoAzureVNET"
$ContosoAzureVNETPrefix = "10.6.0.0/16"
$ContosoAzureVMETSubnet1Name = "ContosoAzureSubnet"
$ContosoAzureVMETSubnet1Prefix = "10.6.0.0/24"
$ContosoAzureVMETSubnet2Name = "GatewaySubnet"
$ContosoAzureVMETSubnet2Prefix = "10.6.1.0/29"
$ContosoAzureVPNGatewayName = "ContosoAzure2OnPremGW"
$ContosoAzureVPNPublicIP = "ContosoAzureVNETGWIP"
$ContosoAzureConnection  = "ContosoS2S"
$ContosoAzureVPNGatewayIP = ""
$ContosoAzureVPNGatewayIPName = "ContosoAzureVNETGWIP"

$ContosoOnPremVNETName = "ContosoOnPremVNET"
$ContosoOnPremVNETPrefix = "10.5.0.0/16"
$ContosoOnPremVMETSubnet1Name = "ContosoAzureSubnet"
$ContosoOnPremVMETSubnet1Prefix = "10.5.0.0/24"
$ContosoOnPremVMETSubnet2Name = "GatewaySubnet"
$ContosoOnPremVMETSubnet2Prefix = "10.5.1.0/29"
$ContosoOnPremLocalNetworkGatewayName = "ContosoOnPrem2AzureGW"
$ContosoOnPremVPNGatewayName = "ContosoOnPrem2AzureGW"
$ContosoOnPremVPNPublicIP = "ContosoOnPremVNETGWIP"
$ContosoOnPremConnection  = "ContosoS2S"
$ContosoOnPremVPNGatewayIP = ""

$AzureHQRG = "ContosoAzureHQ"
$AzureHQTemplate = "https://raw.githubusercontent.com/opsgility/oms-evergreen/master/OMSEGDeploy/OMSEGDeploy/azuredeploy.json"

$OnPremHQRG = "ContosoOnPremHQ"
$OnPremHQRGTemplate = "https://raw.githubusercontent.com/opsgility/oms-evergreen/master/OMSEGDeploy/ContosoOnPremHQ/azuredeploy.json"

# Deploy Azure HQ template 
New-AzureRmResourceGroup -Name $AzureHQRG -Location $AzureHQLocation -Force
New-AzureRmResourceGroupDeployment -Name "ContosoAzureHQDeploy" `
                                   -ResourceGroupName $AzureHQRG `
                                   -TemplateFile $AzureHQTemplate `
                                   -Mode Incremental 

# Deploy OnPrem Resource Group 
New-AzureRmResourceGroup -Name $OnPremHQRG -Location $AzureOnPremLocation -Force

# Wire up S2S connectivity 

$ContosoAzureVPNGatewayIP = Get-AzureRmPublicIpAddress -ResourceGroupName $AzureHQRG -Name $ContosoAzureVPNGatewayIPName

$subnets = @()

$subnets += New-AzureRmVirtualNetworkSubnetConfig -Name $ContosoOnPremVMETSubnet1Name `
                                -AddressPrefix $ContosoAzureVMETSubnet1Prefix

$subnets += New-AzureRmVirtualNetworkSubnetConfig -Name $ContosoOnPremVMETSubnet2Name `
                                -AddressPrefix $ContosoAzureVMETSubnet2Prefix

New-AzureRmVirtualNetwork -Name $ContosoOnPremVNETName `
                          -ResourceGroupName $OnPremHQRG `
                          -Location $AzureOnPremLocation `
                          -AddressPrefix $ContosoAzureVNETPrefix `
                          -DnsServer $ContosoDNSIP `
                          -Subnet $subnets

New-AzureRmLocalNetworkGateway -Name $ContosoOnPremLocalNetworkGatewayName `
                               -Location $AzureOnPremLocation `
                               -ResourceGroupName $OnPremHQRG `
                               -GatewayIpAddress $ContosoAzureVPNGatewayIP.IpAddress `
                               -AddressPrefix $ContosoAzureVNETPrefix 

$gwpip = New-AzureRmPublicIpAddress -Name $ContosoOnPremVPNPublicIP `
                                    -ResourceGroupName $OnPremHQRG `
                                    -Location $AzureOnPremLocation `
                                    -AllocationMethod Dynamic

$vnet = Get-AzureRmVirtualNetwork -Name $ContosoOnPremVNETName -ResourceGroupName $OnPremHQRG
$subnet = Get-AzureRmVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $vnet
$gwipconfig = New-AzureRmVirtualNetworkGatewayIpConfig -Name gwipconfig1 -SubnetId $subnet.Id -PublicIpAddressId $gwpip.Id

New-AzureRmVirtualNetworkGateway -Name $ContosoOnPremVPNGatewayName `
                                -ResourceGroupName $OnPremHQRG `
                                -Location $AzureOnPremLocation `
                                -IpConfigurations $gwipconfig `
                                -GatewayType Vpn `
                                -VpnType RouteBased `
                                -GatewaySku Basic


$gateway1 = Get-AzureRmVirtualNetworkGateway -Name $ContosoOnPremVPNGatewayName -ResourceGroupName $OnPremHQRG
$local = Get-AzureRmLocalNetworkGateway -Name $ContosoOnPremLocalNetworkGatewayName -ResourceGroupName $OnPremHQRG

New-AzureRmVirtualNetworkGatewayConnection -Name $ContosoOnPremConnection `
                                           -ResourceGroupName $OnPremHQRG `
                                           -Location $AzureOnPremLocation `
                                           -VirtualNetworkGateway1 $gateway1 `
                                           -LocalNetworkGateway2 $local `
                                            -ConnectionType IPsec -RoutingWeight 10 -SharedKey 'Abc321'


#New-AzureRmResourceGroupDeployment -Name "ContosoOnPremHQDeploy" -ResourceGroupName $OnPremHQRG -TemplateFile $OnPremHQRGTemplate -Mode Incremental 