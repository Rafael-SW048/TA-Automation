$logFile = "C:\script.log"
"Starting script disable-screensaver.ps1" | Out-File -FilePath $logFile -Append

Write-Output "Disabling Screensaver"
Set-ItemProperty "HKCU:\Control Panel\Desktop" -Name ScreenSaveActive -Value 0 -Type DWord
& powercfg -x -monitor-timeout-ac 0
& powercfg -x -monitor-timeout-dc 0

"Finished script disable-screensaver.ps1" | Out-File -FilePath $logFile -Append