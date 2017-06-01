$Cred = Get-AutomationPSCredential -Name 'AzureCredential'
$null = Add-AzureRmAccount -Credential $Cred -ErrorAction Stop
		
$SubId = Get-AutomationVariable -Name 'AzureSubscriptionId'
$null = Set-AzureRmContext -SubscriptionId $SubId -ErrorAction Stop
		
$VmName = "StoreSrv001"
$ResourceGroupName = "ContosoRetailStore001"

try {
    $vm = Get-AzureRmVm -ResourceGroupName $ResourceGroupName -VMName $VmName -ErrorAction Stop
} catch {
    Write-Error "Virtual Machine not found"
    exit
}
$currentVMSize = $vm.HardwareProfile.vmSize
	
Write-Output "`nFound the specified Virtual Machine: $VmName"
Write-Output "Current size: $currentVMSize"
		
$newVMSize = ""
		
$newVMSize = "Standard_D2_v2"
if($newVMSize -eq $currentVMSize) 
{
	Write-Output "The current Virtual Machine size is the same as the new size"
} 
else 
{
    Write-Output "`nNew size will be: $newVMSize"
				
	$vm.HardwareProfile.VmSize = $newVMSize
	Update-AzureRmVm -VM $vm -ResourceGroupName $ResourceGroupName
			
	$updatedVm = Get-AzureRmVm -ResourceGroupName $ResourceGroupName -VMName $VmName
	$updatedVMSize = $updatedVm.HardwareProfile.vmSize
			
	Write-Output "`nSize updated to: $updatedVMSize"	
}