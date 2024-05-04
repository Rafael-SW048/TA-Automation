$logFile = "C:\script.log"
"Starting script disable-winrm.ps1" | Out-File -FilePath $logFile -Append

Write-Output "Disable WinRM"
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new enable=yes action=block
netsh advfirewall firewall set rule group="Windows Remote Management" new enable=yes
$winrmService = Get-Service -Name WinRM
if ($winrmService.Status -eq "Running") {
  Disable-PSRemoting -Force
}
Stop-Service winrm
Set-Service -Name winrm -StartupType Disabled

"Finished script disable-winrm.ps1" | Out-File -FilePath $logFile -Append