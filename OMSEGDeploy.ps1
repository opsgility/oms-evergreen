param($vpnSharedKey, $subscriptionName)

Select-AzureRmSubscription -SubscriptionName $subscriptionName

$AzureHQLocation = "East US"
$AzureOnPremLocation = "West US"

# Virtual Network Configurations 
$ContosoDNSIP = "10.6.0.4"

$ContosoAzureVNETName = "ContosoAzureVNET"
$ContosoAzureVNETPrefix = "10.6.0.0/16"
$ContosoAzureVNETSubnet1Name = "ContosoAzureSubnet"
$ContosoAzureVNETSubnet1Prefix = "10.6.0.0/24"
$ContosoAzureVNETSubnet2Name = "GatewaySubnet"
$ContosoAzureVNETSubnet2Prefix = "10.6.1.0/29"
$ContosoAzureVPNGatewayName = "ContosoAzure2OnPremGW"
$ContosoAzureLocalNetworkGatewayName = "ContosoAzure2OnPremGW"
$ContosoAzureVPNPublicIPName = "ContosoAzureVNETGWIP"
$ContosoAzureConnection  = "ContosoS2S"
$ContosoAzureVPNGatewayIP = ""


$ContosoOnPremVNETName = "ContosoOnPremVNET"
$ContosoOnPremVNETPrefix = "10.5.0.0/16"
$ContosoOnPremVNETSubnet1Name = "ContosoAzureSubnet"
$ContosoOnPremVNETSubnet1Prefix = "10.5.0.0/24"
$ContosoOnPremVNETSubnet2Name = "GatewaySubnet"
$ContosoOnPremVNETSubnet2Prefix = "10.5.1.0/29"
$ContosoOnPremLocalNetworkGatewayName = "ContosoOnPrem2AzureGW"
$ContosoOnPremVPNGatewayName = "ContosoOnPrem2AzureGW"
$ContosoOnPremVPNPublicIPName = "ContosoOnPremVNETGWIP"
$ContosoOnPremConnection  = "ContosoS2S"
$ContosoOnPremVPNGatewayIP = ""

$AzureHQRG = "ContosoAzureHQ"
$OnPremHQRG = "ContosoOnPremHQ"

$AzureHQTemplate = "https://raw.githubusercontent.com/opsgility/oms-evergreen/master/OMSEGDeploy/OMSEGDeploy/azuredeploy.json"
$OnPremHQRGTemplate = "https://raw.githubusercontent.com/opsgility/oms-evergreen/master/OMSEGDeploy/ContosoOnPremHQ/azuredeploy.json"

# Deploy Azure HQ template 
New-AzureRmResourceGroup -Name $AzureHQRG -Location $AzureHQLocation -Force
New-AzureRmResourceGroupDeployment -Name "ContosoAzureHQDeploy" `
                                   -ResourceGroupName $AzureHQRG `
                                   -TemplateFile $AzureHQTemplate `
                                   -Mode Incremental 

# Create OnPrem Resource Group 
New-AzureRmResourceGroup -Name $OnPremHQRG -Location $AzureOnPremLocation -Force

# Wire up S2S connectivity 
$gwpip = New-AzureRmPublicIpAddress -Name $ContosoOnPremVPNPublicIPName `
                                    -ResourceGroupName $OnPremHQRG `
                                    -Location $AzureOnPremLocation `
                                    -AllocationMethod Dynamic

$ContosoAzureVPNGatewayIP = Get-AzureRmPublicIpAddress -ResourceGroupName $AzureHQRG -Name $ContosoAzureVPNPublicIPName 
$ContosoOnPremVPNPublicIP = Get-AzureRmPublicIpAddress -ResourceGroupName $OnPremHQRG -Name $ContosoOnPremVPNPublicIPName

Write-Host "Creating the virtual network and gateway for $ContosoOnPremVNETName" 
$subnets = @()
$subnets += New-AzureRmVirtualNetworkSubnetConfig -Name $ContosoOnPremVNETSubnet1Name `
                                -AddressPrefix $ContosoOnPremVNETSubnet1Prefix
$subnets += New-AzureRmVirtualNetworkSubnetConfig -Name $ContosoOnPremVNETSubnet2Name `
                                -AddressPrefix $ContosoOnPremVNETSubnet2Prefix

New-AzureRmVirtualNetwork -Name $ContosoOnPremVNETName `
                          -ResourceGroupName $OnPremHQRG `
                          -Location $AzureOnPremLocation `
                          -AddressPrefix $ContosoOnPremVNETPrefix `
                          -DnsServer $ContosoDNSIP `
                          -Subnet $subnets

New-AzureRmLocalNetworkGateway -Name $ContosoOnPremLocalNetworkGatewayName `
                               -Location $AzureOnPremLocation `
                               -ResourceGroupName $OnPremHQRG `
                               -GatewayIpAddress $ContosoAzureVPNGatewayIP.IpAddress `
                               -AddressPrefix $ContosoAzureVNETPrefix 
                               

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



Write-Host "Creating connections between gateways" 

$gwOnPremVPN    = Get-AzureRmVirtualNetworkGateway -Name $ContosoOnPremVPNGatewayName -ResourceGroupName $OnPremHQRG
$gwOnPremLocal  = Get-AzureRmLocalNetworkGateway -Name $ContosoOnPremLocalNetworkGatewayName -ResourceGroupName $OnPremHQRG

$gwAzureVPN  = Get-AzureRmVirtualNetworkGateway -Name $ContosoAzureVPNGatewayName -ResourceGroupName $AzureHQRG
$gwAzureLocal     = Get-AzureRmLocalNetworkGateway -Name $ContosoAzureLocalNetworkGatewayName -ResourceGroupName $AzureHQRG



Write-Host "Updating existing local network gateway (Azure HQ) IP to new gateway address (OnPrem HQ)" 
$ContosoOnPremVPNPublicIP = Get-AzureRmPublicIpAddress -ResourceGroupName $OnPremHQRG -Name $ContosoOnPremVPNPublicIPName

$gwAzureLocal.GatewayIpAddress = $ContosoOnPremVPNPublicIP.IpAddress
Set-AzureRmLocalNetworkGateway -LocalNetworkGateway $gwAzureLocal

New-AzureRmVirtualNetworkGatewayConnection -Name $ContosoOnPremConnection `
                                           -ResourceGroupName $OnPremHQRG `
                                           -Location $AzureOnPremLocation `
                                           -VirtualNetworkGateway1 $gwOnPremVPN `
                                           -LocalNetworkGateway2 $gwOnPremLocal `
                                            -ConnectionType IPsec -RoutingWeight 10 -SharedKey $vpnSharedKey

New-AzureRmVirtualNetworkGatewayConnection -Name $ContosoAzureConnection `
                                           -ResourceGroupName $AzureHQRG `
                                           -Location $AzureHQLocation `
                                           -VirtualNetworkGateway1 $gwAzureVPN `
                                           -LocalNetworkGateway2 $gwAzureLocal `
                                           -ConnectionType IPsec -RoutingWeight 10 -SharedKey $vpnSharedKey -Force

Write-Host "Waiting for connectivity before continuing... " 


$con1 = Get-AzureRmVirtualNetworkGatewayConnection -Name $ContosoOnPremConnection -ResourceGroupName $OnPremHQRG 
$con2 = Get-AzureRmVirtualNetworkGatewayConnection -Name $ContosoAzureConnection -ResourceGroupName $AzureHQRG 

while($true)
{
    $con1 = Get-AzureRmVirtualNetworkGatewayConnection -Name $ContosoOnPremConnection -ResourceGroupName $OnPremHQRG 
    $con2 = Get-AzureRmVirtualNetworkGatewayConnection -Name $ContosoAzureConnection -ResourceGroupName $AzureHQRG 
    Write-Host "$OnPremHQRG $ContosoOnPremConnection Status: " $con1.ConnectionStatus 
    Write-Host "$AzureHQRG $ContosoAzureConnection Status: " $con2.ConnectionStatus 

    if($con1.ConnectionStatus -eq "Connected" -and $con2.ConnectionStatus -eq "Connected"){
        break
    }
    Write-Host "Checking again in 15 seconds"
    Start-Sleep -Seconds 15
}

New-AzureRmResourceGroupDeployment -Name "ContosoOnPremHQDeploy" -ResourceGroupName $OnPremHQRG -TemplateFile $OnPremHQRGTemplate -Mode Incremental 