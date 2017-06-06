param($domain, $user, $password, $dbsource)

$logs = "C:\Logs"
$data = "C:\Data"
$backups = "C:\Backup" 
[system.io.directory]::CreateDirectory($logs)
[system.io.directory]::CreateDirectory($data)
[system.io.directory]::CreateDirectory($backups)
[system.io.directory]::CreateDirectory("C:\SQLDATA")

# Setup the data, backup and log directories as well as mixed mode authentication
Import-Module "sqlps" -DisableNameChecking
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
$sqlesq = new-object ('Microsoft.SqlServer.Management.Smo.Server') Localhost
$sqlesq.Settings.LoginMode = [Microsoft.SqlServer.Management.Smo.ServerLoginMode]::Mixed
$sqlesq.Settings.DefaultFile = $data
$sqlesq.Settings.DefaultLog = $logs
$sqlesq.Settings.BackupDirectory = $backups
$sqlesq.Alter() 

# Restart the SQL Server service
Restart-Service -Name "MSSQLSERVER" -Force
# Re-enable the sa account and set a new password to enable login
Invoke-Sqlcmd -ServerInstance Localhost -Database "master" -Query "ALTER LOGIN sa ENABLE"
Invoke-Sqlcmd -ServerInstance Localhost -Database "master" -Query "ALTER LOGIN sa WITH PASSWORD = 'Demo@pass1'"

# Get the Adventure works database backup 
$dbdestination = "C:\SQLDATA\AdventureWorks2012.bak"
Invoke-WebRequest $dbsource -OutFile $dbdestination 

$mdf = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("AdventureWorks2012_Data", "C:\Data\AdventureWorks2012.mdf")
$ldf = New-Object Microsoft.SqlServer.Management.Smo.RelocateFile("AdventureWorks2012_Log", "C:\Logs\AdventureWorks2012.ldf")

# Restore the database from the backup
Restore-SqlDatabase -ServerInstance Localhost -Database AdventureWorks `
			-BackupFile $dbdestination -RelocateFile @($mdf,$ldf)  
New-NetFirewallRule -DisplayName "SQL Server" -Direction Inbound –Protocol TCP –LocalPort 1433 -Action allow 


$smPassword = (ConvertTo-SecureString $password -AsPlainText -Force)
$user = "$domain\$user"
$objCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($user, $smPassword)
Add-Computer -DomainName "$domain" -Credential $objCred -Restart -Force