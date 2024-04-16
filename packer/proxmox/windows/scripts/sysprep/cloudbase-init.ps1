# install Cloudbase-Init
echo "Create setup directory"
mkdir "c:\setup"

echo "Copy CloudbaseInitSetup_1_1_4_x64.msi"
copy-item "G:\sysprep\CloudbaseInitSetup_1_1_4_x64.msi" "c:\setup\CloudbaseInitSetup_1_1_4_x64.msi" -force

echo "Start process CloudbaseInitSetup_1_1_4_x64.msi"

# Define the file path
$msiPath = "C:\setup\CloudbaseInitSetup_1_1_4_x64.msi"
$logPath = "C:\setup\cloud-init.log"

# Launch the installer and capture logs
$exitCode = Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i `"$msiPath`" /qn /l*v `"$logPath`"" -Wait -PassThru

# Check installation status
if ($exitCode.ExitCode -eq 0) {
  Write-Host "Installation successful! Log saved to $logPath"
} else {
  Write-Host "Installation failed with exit code: $($exitCode.ExitCode)"
}

Start-Sleep 120

# Cloudbase-init Part 2

while (!(Select-String -Path 'C:\setup\cloud-init.log' -Pattern 'Installation completed successfully' -Quiet)) {
  echo "Wait cloud-init installation end..."
  Start-Sleep 5
}

# Check if cloudbase-init service is running, if not, start the service
echo "Show cloudinit service"
Get-Service -Name cloudbase-init

if ((Get-Service -Name cloudbase-init).Status -ne 'Running') {
  echo "Starting cloudbase-init service"
  Start-Service -Name cloudbase-init
}

echo "Move config files to location"
# Move conf files to Cloudbase directory
copy-item "G:\sysprep\cloudbase-init.conf" "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init.conf" -force
copy-item "G:\sysprep\cloudbase-init-unattend.conf" "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init-unattend.conf" -force
copy-item "G:\sysprep\cloudbase-init-unattend.xml" "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init-unattend.xml" -force

echo "Disable cloudbaseinit at start"
# disable cloudbase-init start
Set-Service -Name cloudbase-init -StartupType Disabled

# Run sysprep
cd "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\"
start-process -FilePath "C:/Windows/system32/sysprep/sysprep.exe" -ArgumentList "/generalize /oobe /mode:vm /unattend:cloudbase-init-unattend.xml" -wait

