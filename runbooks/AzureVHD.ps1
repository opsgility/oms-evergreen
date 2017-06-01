#############################################################################
#                                     			 		                    #
#   This Sample Code is provided for the purpose of illustration only       #
#   and is not intended to be used in a production environment.  THIS       #
#   SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT    #
#   WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT    #
#   LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS     #
#   FOR A PARTICULAR PURPOSE.  We grant You a nonexclusive, royalty-free    #
#   right to use and modify the Sample Code and to reproduce and distribute #
#   the object code form of the Sample Code, provided that You agree:       #
#   (i) to not use Our name, logo, or trademarks to market Your software    #
#   product in which the Sample Code is embedded; (ii) to include a valid   #
#   copyright notice on Your software product in which the Sample Code is   #
#   embedded; and (iii) to indemnify, hold harmless, and defend Us and      #
#   Our suppliers from and against any claims or lawsuits, including        #
#   attorneys' fees, that arise or result from the use or distribution      #
#   of the Sample Code.                                                     #
#                                     			 		                    #
#   Version 1.0                              			 	                #
#   Last Update Date: 21 April 2017                           	            #
#                                     			 		                    #
#############################################################################

#Requires -version 4
#Requires -module AzureRM.Profile,AzureRM.Compute,AzureRM.Storage

Login-AzureRmAccount -ErrorVariable loginerror

If ($loginerror -ne $null)
{
Throw {"Error: An error occured during the login process, please correct the error and try again."}
}

Write-Host "Retrieving all VHD URI's from Storage Account" -ForegroundColor Green

$Data = @{}

Foreach ($Store in @(Get-AzureRmStorageAccount))
{
       Foreach ($container in @(Get-AzureStorageContainer -Context $store.Context )){
            
            Foreach ($blob in @(Get-AzureStorageBlob -Container $container.name -Context $store.Context ))
            {
                IF ($blob.Name -like '*.vhd')
                {
                 $data."$($blob.name)" = [PSCustomObject]@{Container = $container.name
                                          StorageAccount = $store.StorageAccountName 
                                          VMName = '' 
                                          vhd = $blob.Name}
                }
            }
    }
}

Write-host "Retrieving all VM's" -ForegroundColor green
    foreach ($VM in @(Get-AzureRMVM -WarningAction SilentlyContinue))
    {
    $disks = @()
    $disks += $vm.StorageProfile.OsDisk.vhd.uri
    $disks +=  ($vm.StorageProfile.DataDisks.vhd.uri)
    $disk = @() ; 
    $disks |  %{$disk += if (($_ -Split '/')[-1] -ne ''){($_ -Split '/')[-1]}}
    $disk |%{$Data."$_".VMName = $Vm.Name}
    }
Write-Host "Comparing results" -ForegroundColor Green


$CSS = @"
<Title>Capacity Report:$(Get-Date -Format 'dd MMMM yyyy' )</Title>
<Style>
th {
	font: bold 11px "Trebuchet MS", Verdana, Arial, Helvetica,
	sans-serif;
	color: #FFFFFF;
	border-right: 1px solid #C1DAD7;
	border-bottom: 1px solid #C1DAD7;
	border-top: 1px solid #C1DAD7;
	letter-spacing: 2px;
	text-transform: uppercase;
	text-align: left;
	padding: 6px 6px 6px 12px;
	background: #5F9EA0;
}
td {
	font: 11px "Trebuchet MS", Verdana, Arial, Helvetica,
	sans-serif;
	border-right: 1px solid #C1DAD7;
	border-bottom: 1px solid #C1DAD7;
	background: #fff;
	padding: 6px 6px 6px 12px;
	color: #6D929B;
}
</Style>
"@

($data.Keys | %{$data.$_ } | Sort-Object -Property VMName | `
Select @{Name='VMName';E={IF ($_.VMName -eq ''){'Not Attached'}Else{$_.VMName}}},StorageAccount,Container,vhd |`
ConvertTo-Html -Head $CSS ).replace('Not Attached','<font color=red>Not Attached</font>')| Out-File .\VHDReport.html
Invoke-Item .\VHDReport.html

