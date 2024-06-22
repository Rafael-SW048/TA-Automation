$retryCount = 10
$retryDelay = 5  # seconds
$cloneSuccess = $false

# Check if the directory exists and delete it if it does
if (Test-Path "C:\setup\scripts\ZeroTierAuto") {
    echo "Removing existing ZeroTierAuto directory..." | Out-File -Append -FilePath "C:\setup\apps\ZeroTierAuto.log"
    Remove-Item -Path "C:\setup\scripts\ZeroTierAuto" -Recurse -Force
}

# Retry loop for cloning the repository
for ($i = 1; $i -le $retryCount; $i++) {
  echo "Attempt ${i}: Cloning network configuration dependencies in $retryDelay seconds." | Out-File -Append -FilePath "C:\setup\apps\ZeroTierAuto.log"
  try {
    Start-Sleep -Seconds $retryDelay
    echo "Attempt ${i}: Cloning network configuration dependencies..." | Out-File -Append -FilePath "C:\setup\apps\ZeroTierAuto.log"
    git clone https://github.com/JordanSihombing/ZeroTierAuto.git "C:\setup\scripts\ZeroTierAuto"
    
    # Check if the directory was successfully cloned
    if (Test-Path "C:\setup\scripts\ZeroTierAuto") {
        $cloneSuccess = $true
        echo "ZeroTierAuto installation successful!" | Out-File -Append -FilePath "C:\setup\apps\ZeroTierAuto.log"
        break
    } else {
        echo "Clone failed for attempt ${i}." | Out-File -Append -FilePath "C:\setup\apps\ZeroTierAuto.log"
        throw "Clone failed."
    }
  } catch {
    $errorMessage = "Attempt ${i}: ZeroTierAuto installation failed with error: $_"
    echo $errorMessage | Out-File -Append -FilePath "C:\setup\apps\ZeroTierAuto.log"
    if ($i -eq $retryCount) {
      throw $errorMessage
    }
  }
}

if ($cloneSuccess) {
  try {
    echo "Starting ZeroTierAuto..." | Out-File -Append -FilePath "C:\setup\apps\ZeroTierAuto.log"
    Start-Process -WorkingDirectory "C:\setup\scripts\ZeroTierAuto" -WindowStyle Hidden -FilePath "powershell" -ArgumentList ".\controller\vmStart.ps1" | Out-File -Append -FilePath "C:\setup\apps\ZeroTierAuto.log"
  } catch {
    echo "Failed to start ZeroTierAuto with error: $_" | Out-File -Append -FilePath "C:\setup\apps\ZeroTierAuto.log"
  }
} else {
  echo "ZeroTierAuto installation failed after $retryCount attempts." | Out-File -Append -FilePath "C:\setup\apps\ZeroTierAuto.log"
}
