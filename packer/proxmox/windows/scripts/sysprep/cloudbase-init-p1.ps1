try {
  # install Cloudbase-Init
  echo "Create setup directory"
  mkdir "c:\setup" -ErrorAction Stop
  echo "Done"

  echo "Copy CloudbaseInitSetup_1_1_4_x64.msi"
  copy-item "G:\sysprep\CloudbaseInitSetup_1_1_4_x64.msi" "c:\setup\CloudbaseInitSetup_1_1_4_x64.msi" -force -ErrorAction Stop
  echo "Done"

  echo "Start process CloudbaseInitSetup_1_1_4_x64.msi"

  # Define the file path
  $msiPath = "C:\setup\CloudbaseInitSetup_1_1_4_x64.msi"
  $logPath = "C:\setup\cloud-init.log"

  # Launch the installer and capture logs
  $exitCode = Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i `"$msiPath`" /qn /l*v `"$logPath`"" -Wait -PassThru -ErrorAction Stop
  # $exitCode = Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i `"$msiPath`" /qn /l*v `"$logPath`"" -Verb RunAs -Wait -PassThru -ErrorAction Stop

  # Check installation status
  if ($exitCode.ExitCode -eq 0) {
    Write-Host "Installation successful! Log saved to $logPath"
  } else {
    Write-Host "Installation failed with exit code: $($exitCode.ExitCode)"
  }

  echo "Done"
} catch {
  Write-Output "This is the error...  Error Details: $($_.Exception.Message)"
}