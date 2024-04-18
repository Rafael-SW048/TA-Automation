Try {
  Start-Sleep 30

  while (!(Select-String -Path 'C:\setup\cloud-init.log' -Pattern 'Installation completed successfully' -Quiet)) {
    echo "Wait cloud-init installation end..."
    Start-Sleep 5
  }

  echo "Show cloudinit service"
  Get-Service -Name cloudbase-init -ErrorAction Stop

  echo "Move config files to location"
  # Move conf files to Cloudbase directory
  copy-item "G:\sysprep\cloudbase-init.conf" "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init.conf" -force -ErrorAction Stop
  copy-item "G:\sysprep\cloudbase-init-unattend.conf" "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init-unattend.conf" -force -ErrorAction Stop
  copy-item "G:\sysprep\cloudbase-init-unattend.xml" "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init-unattend.xml" -force -ErrorAction Stop

  echo "Disable cloudbaseinit at start"
  # disable cloudbase-init start
  Set-Service -Name cloudbase-init -StartupType Disabled -ErrorAction Stop

  # Run sysprep
  echo "Run sysprep"
  cd "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\"
  start-process -FilePath "C:/Windows/system32/sysprep/sysprep.exe" -ArgumentList "/generalize /oobe /mode:vm /unattend:cloudbase-init-unattend.xml" -wait -ErrorAction Stop
}
Catch {
  Write-Output "This is the error...  Error Details: $($_.Exception.Message)"
}