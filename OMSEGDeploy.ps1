cls
Select-AzureRmSubscription -SubscriptionName "opsgilitytraining"

$location = "East US"

$AzureHQRG = "ContosoAzureHQ"
$AzureHQTemplate = "https://raw.githubusercontent.com/opsgility/oms-evergreen/master/OMSEGDeploy/OMSEGDeploy/azuredeploy.json"

$OnPremHQRG = "ContosoOnPremHQ"
$OnPremHQRGTemplate = "https://raw.githubusercontent.com/opsgility/oms-evergreen/master/OMSEGDeploy/ContosoOnPremHQ/azuredeploy.json"

New-AzureRmResourceGroup -Name $AzureHQRG -Location $location -Force
New-AzureRmResourceGroupDeployment -Name "ContosoAzureHQDeploy" -ResourceGroupName $AzureHQRG -TemplateFile $AzureHQTemplate -Mode Incremental 


# After deployement - retrieve public IP addresses and update gateways 


#New-AzureRmResourceGroup -Name $OnPremHQRG -Location $location -Force
#New-AzureRmResourceGroupDeployment -Name "ContosoOnPremHQDeploy" -ResourceGroupName $OnPremHQRG -TemplateFile $OnPremHQRGTemplate -Mode Incremental 