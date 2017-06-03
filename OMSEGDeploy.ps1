cls
Select-AzureRmSubscription -SubscriptionName "opsgilitytraining"

$hqRG = "ContosoAzureHQ"
$location = "East US"
$hqTemplate = "https://raw.githubusercontent.com/opsgility/oms-evergreen/master/OMSEGDeploy/OMSEGDeploy/azuredeploy.json"
$hqTemplateFile = "C:\repos\oms-evergreen\OMSEGDeploy\OMSEGDeploy\azuredeploy.json"

New-AzureRmResourceGroup -Name $hqRG -Location $location -Force

#New-AzureRmResourceGroupDeployment -Name "ContosoAzureHQDeploy" -ResourceGroupName $hqRG -TemplateUri $hqTemplate -Mode Incremental 
New-AzureRmResourceGroupDeployment -Name "ContosoAzureHQDeploy" -ResourceGroupName $hqRG -TemplateFile $hqTemplateFile -Mode Incremental 