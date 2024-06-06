try {
  echo "Waiting for network to be ready..."
  ipconfig /release "Ethernet"
  ipconfig /renew "Ethernet"
  # Disable firewall
	echo "Disabling firewall..."
	Set-NetFirewallProfile -All -Enabled False
  Start-Sleep 5
  echo "Cloning network configuration dependencies..."
  # Cloning network configuration dependencies
  git clone https://github.com/JordanSihombing/ZeroTierAuto.git "C:\setup\scripts\ZeroTierAuto"
  echo "ZeroTierAuto installation successful!" | Out-File -Append -FilePath "C:\setup\apps\ZeroTierAuto.log"

  echo "starting ZeroTierAuto..." | Out-File -Append -FilePath "C:\setup\apps\ZeroTierAuto.log"
  Start-Process -WorkingDirectory "C:\setup\scripts\ZeroTierAuto" -WindowStyle Hidden  -FilePath "powershell" -ArgumentList ".\controller\vmStart.ps1" | Out-File -Append -FilePath "C:\setup\apps\ZeroTierAuto.log"
} catch {
  echo "ZeroTierAuto installation failed with error: $_" | Out-File -Append -FilePath "C:\setup\apps\ZeroTierAuto.log"
}