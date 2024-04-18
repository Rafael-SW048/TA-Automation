Try {
  Start-Sleep 30
  # install Cloudbase-Init
  echo "Copy KMS_VL_ALL_AIO.cmd"
  copy-item "G:\sysprep\KMS_VL_ALL_AIO.cmd" "c:\setup\KMS_VL_ALL_AIO.cmd" -force -ErrorAction Stop
  echo "Done"

  echo "Start process KMS_VL_ALL_AIO.cmd"

  # Define the file path
  $kmsPath = "C:\setup\KMS_VL_ALL_AIO.cmd"

  # Launch the activator
  $exitCode = Start-Process -FilePath cmd.exe -ArgumentList "/c $kmsPath" -Wait -PassThru -ErrorAction Stop

  # Check installation status
  if ($exitCode.ExitCode -eq 0) {
    Write-Host "Activation successful!"
  } else {
    Write-Host "Activation failed with exit code: $($exitCode.ExitCode)"
  }

  echo "Done"
  echo "---------------------------------------------"
} Catch {
  Write-Output "This is the error...  Error Details: $($_.Exception.Message)"
}