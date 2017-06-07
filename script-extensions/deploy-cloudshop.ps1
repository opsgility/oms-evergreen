param($domain, $user, $password, $cloudShopUrl)



add-WindowsFeature -Name "Web-Server" -IncludeAllSubFeature




$splitpath = $cloudShopUrl.Split("/")

$fileName = $splitpath[$splitpath.Length-1]

$destinationPath = "C:\Inetpub\wwwroot\CloudShop.zip"

$destinationFolder = "C:\Inetpub\wwwroot"



$WebClient = New-Object System.Net.WebClient
$WebClient.DownloadFile($cloudShopUrl,$destinationPath)



(new-object -com shell.application).namespace($destinationFolder).CopyHere((new-object -com shell.application).namespace($destinationPath).Items(),16)





$smPassword = (ConvertTo-SecureString $password -AsPlainText -Force)

$user = "$domain\$user"

$objCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($user, $smPassword)

Add-Computer -DomainName "$domain" -Credential $objCred -Restart -Force
