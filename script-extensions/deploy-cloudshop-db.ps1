param($domain, $user, $password, $dbsource, $sqlConfigUrl)

$logs = "C:\Logs"
$data = "C:\Data"
$backups = "C:\Backup" 
$script  = "C:\Script" 

[system.io.directory]::CreateDirectory($logs)
[system.io.directory]::CreateDirectory($data)
[system.io.directory]::CreateDirectory($backups)
[system.io.directory]::CreateDirectory($script)
[system.io.directory]::CreateDirectory("C:\SQLDATA")

$splitpath = $sqlConfigUrl.Split("/")
$fileName = $splitpath[$splitpath.Length-1]
$destinationPath = "$script\configure-sql.ps1"

(New-Object Net.WebClient).DownloadFile($sqlConfigUrl,$destinationPath);

$password =  ConvertTo-SecureString "$password" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential("$env:COMPUTERNAME\$user", $password)
$command = $file = $PSScriptRoot + "\configure-sql.ps1"
Enable-PSRemoting –force
Invoke-Command -FilePath $destinationPath -Credential $credential -ComputerName $env:COMPUTERNAME
Disable-PSRemoting -Force

New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound –Protocol TCP –LocalPort 1433 -Action allow 



$smPassword = (ConvertTo-SecureString $password -AsPlainText -Force)
$user = "$domain\$user"
$objCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($user, $smPassword)
Add-Computer -DomainName "$domain" -Credential $objCred -Restart -Force