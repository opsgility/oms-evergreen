cls
Select-AzureRmSubscription -SubscriptionName "opsgilitytraining"

$location = "East US"

$AzureHQRG = "ContosoAzureHQ"
$AzureHQTemplate = "https://raw.githubusercontent.com/opsgility/oms-evergreen/master/OMSEGDeploy/OMSEGDeploy/azuredeploy.json"

$OnPremHQRG = "ContosoOnPremHQ"
$OnPremHQRGTemplate = ""

New-AzureRmResourceGroup -Name $AzureHQRG -Location $location -Force
New-AzureRmResourceGroupDeployment -Name "ContosoAzureHQDeploy" -ResourceGroupName $AzureHQRG -TemplateFile $AzureHQTemplate -Mode Incremental 




