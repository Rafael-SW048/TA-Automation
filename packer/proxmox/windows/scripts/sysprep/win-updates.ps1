try {
  # Check if PSWindowsUpdate module is installed, if not, install it
  if (-not(Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    if (-not(Get-PackageProvider -ListAvailable -Name NuGet)) {
        Install-PackageProvider -Name NuGet -Force -Confirm:$false
    }
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
}

  # Get available updates
  Write-Output "Getting available updates..."
  Get-WindowsUpdate

  # Install all available updates
  Write-Output "Installing updates..."
  Get-WindowsUpdate -AcceptAll -Install

  # If you want to automatically reboot after installing updates, uncomment the following line:
  # Get-WindowsUpdate -AcceptAll -Install -AutoReboot
}
catch {
  Write-Output "An error occurred. Error Details: $($_.Exception.Message)"
}