$script:isFirstCall = $true

try {
	Write-Output "Creating app directory..."
	New-Item -Path "C:\setup\apps" -ItemType Directory -Force
	Write-Output "Successfully created app directory!" | Out-File -Append -FilePath "C:\setup\apps\installation.log"
} catch {
	Write-Warning "Error occurred while creating app directory: $_"
}

function LogProcess {
    param(
			[string]$Type,
			[string]$Message
    )
    if ($script:isFirstCall) {
			try {
				Write-Output $message | Out-File -Append -FilePath "C:\setup\apps\installation.log" -ErrorAction Stop
			} catch {
				if ($_.Exception.Message -match "Could not find a part of the path") {
					# Create the file and retry logging
					New-Item -Path "C:\setup\apps\installation.log" -ItemType File -Force | Out-Null
					$message | Out-File -Append -FilePath "C:\setup\apps\installation.log" -ErrorAction Stop
				} else {
						Throw "Unexpected error occurred while logging: Type: $Type, Message: $Message, Error:"
				}
			}
			$script:isFirstCall = $false
    }
    try {
			if ($Type -eq "log") {
				$Message | Out-File -Append -FilePath "C:\setup\apps\installation.log" -ErrorAction Stop
				Write-Output $Message
			} elseif ($Type -eq "run") {
				Invoke-Expression $Message | Out-File -Append -FilePath "C:\setup\apps\installation.log" -ErrorAction Stop
			} 
    } catch {
			Write-Output "Error occurred while logging: Type: $Type, Message: $Message, Error: $_"
			# You might want to log this error as well
	}
}

try {
	# Setup app installation
	# LogProcess -Type "log" -Message "Creating app directory..."
	# LogProcess -Type "run" -Message "mkdir 'c:\setup\app' -ErrorAction Stop"
	LogProcess -Type "log" -Message "Done"

	Start-Sleep 3
	LogProcess -Type "log" -Message "------------------------------------------------"
	
	# Check for admin privileges
	if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
		LogProcess -Type "run" -Message "Write-Warning 'You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!'"
		Break
	}

	LogProcess -Type "log" -Message "Installing Scoop..."
	# echo "Setting PS execution policy..." | Out-File -Append -FilePath "C:\setup\apps\installation.log"
	# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
	# echo "Done" 
	try {
    LogProcess -Type "run" -Message "Invoke-RestMethod -Uri https://get.scoop.sh -OutFile 'c:\setup\apps\install.ps1'"
    LogProcess -Type "run" -Message "& 'c:\setup\apps\install.ps1' -RunAsAdmin"
    if ($LASTEXITCODE -eq 1) {
			
    } else {
			LogProcess -Type "run" -Message "throw 'Scoop installation failed with exit code: $LASTEXITCODE'"
    }
	} catch {
    LogProcess -Type "run" -Message "throw 'Scoop installation failed with error: $_'"
	}

	LogProcess -Type "log" -Message "------------------------------------------------"

	LogProcess -Type "log" -Message "Installing Git..."
	try {
		LogProcess -Type "run" -Message "scoop install git"
			LogProcess -Type "log" -Message "Git installation successful!"
	} catch {
			LogProcess -Type "log" -Message "Git installation failed with error: $_"
	}

	LogProcess -Type "log" -Message "------------------------------------------------"

	LogProcess -Type "log" -Message "Proceeding with IddSampleDriver installation..."
	try {
		LogProcess -Type "log" -Message "Adding extraszz bucket "
		LogProcess -Type "run" -Message "scoop bucket add extras"
		LogProcess -Type "log" -Message "Adding nonportable bucket"
		LogProcess -Type "run" -Message "scoop bucket add nonportable"
		LogProcess -Type "log" -Message "Installing IDDSampleDriver"
		LogProcess -Type "run" -Message "scoop install iddsampledriver-ge9-np -g"
		LogProcess -Type "log" -Message "IddSampleDriver installation successful!"
	} catch {
		LogProcess -Type "log" -Message "IddSampleDriver installation failed with error: $_"
	}

	LogProcess -Type "log" -Message "------------------------------------------------"

	Start-Sleep 5
	LogProcess -Type "log" -Message "Editing C:\IddSampleDriver\option.txt..."
	$content = Get-Content -Path "C:\IddSampleDriver\option.txt"
	$content[0] = "1"
	$content | Set-Content -Path "C:\IddSampleDriver\option.txt"
	LogProcess -Type "log" -Message "Done"

	LogProcess -Type "log" -Message "------------------------------------------------"

	LogProcess -Type "log" -Message "Restarting IddSampleDriver..."
	$device = Get-PnpDevice | Where-Object { $_.FriendlyName -eq "IddSampleDriver Device" }
	if ($device) {
			$deviceId = $device.InstanceId
			Disable-PnpDevice -InstanceId $deviceId -Confirm:$false
			Enable-PnpDevice -InstanceId $deviceId -Confirm:$false
			LogProcess -Type "log" -Message "IddSampleDriver restarted!"
	} else {
			LogProcess -Type "log" -Message "IddSampleDriver not found!"
	}

	LogProcess -Type "log" -Message "------------------------------------------------"
	LogProcess -Type "log" -Message "Copy Cloudflare_WARP_2024.3.409.0.msi"
	copy-item "G:\sysprep\apps\Cloudflare_WARP_2024.3.409.0.msi" "c:\setup\apps\Cloudflare_WARP_2024.3.409.0.msi" -force -ErrorAction Stop
	LogProcess -Type "log" -Message "Done"

	LogProcess -Type "log" -Message "Installing Cloudflare..."
	$CFPath = "C:\setup\apps\Cloudflare_WARP_2024.3.409.0.msi"
	$msiarguments = "/quiet /norestart"
	$exitCode = Start-Process -FilePath $CFPath -ArgumentList $msiarguments -Wait -PassThru -ErrorAction Stop

	# Check installation status
	if ($exitCode.ExitCode -eq 0) {
		LogProcess -Type "log" -Message "CloudFlare Installation successful!"
	} else {
		LogProcess -Type "log" -Message "CloudFlare Installation failed with exit code: $($exitCode.ExitCode)"
	}

	LogProcess -Type "log" -Message "------------------------------------------------"
	LogProcess -Type "log" -Message "Copy ZeroTier One.msi"
	copy-item "G:\sysprep\apps\ZeroTier One.msi" "c:\setup\apps\ZeroTier One.msi" -force -ErrorAction Stop
	LogProcess -Type "log" -Message "Done"

	LogProcess -Type "log" -Message "Installing ZeroTier..."
	
	$ZTPath = "C:\setup\apps\ZeroTier One.msi"
	$exitCode = Start-Process -FilePath $ZTPath -ArgumentList $msiarguments -Wait -PassThru -ErrorAction Stop

	if ($exitCode.ExitCode -eq 0) {
		LogProcess -Type "log" -Message "ZeroTier Installation successful!"
	} else {
		LogProcess -Type "log" -Message "ZeroTier Installation failed with exit code: $($exitCode.ExitCode)"
	}

	LogProcess -Type "log" -Message "------------------------------------------------"
	LogProcess -Type "log" -Message "Copy SteamSetup.exe"
	copy-item "G:\sysprep\apps\SteamSetup.exe" "c:\setup\apps\SteamSetup.exe" -force -ErrorAction Stop
	LogProcess -Type "log" -Message "Done"

	LogProcess -Type "log" -Message "Installing Steam..."
	
	$SteamPath = "C:\setup\apps\SteamSetup.exe"
	$exearguments = "/quiet /norestart /silent /S"

	$exitCode = Start-Process -FilePath $SteamPath -ArgumentList $exearguments -Wait -PassThru -ErrorAction Stop

	if ($exitCode.ExitCode -eq 0) {
		LogProcess -Type "log" -Message "Steam Installation successful!"
	} else {
		LogProcess -Type "log" -Message "Steam Installation failed with exit code: $($exitCode.ExitCode)"
	}

	LogProcess -Type "log" -Message "------------------------------------------------"
	LogProcess -Type "log" -Message "Copy sunshine-windows-installer.exe"
	copy-item "G:\sysprep\apps\sunshine-windows-installer.exe" "c:\setup\apps\sunshine-windows-installer.exe" -force -ErrorAction Stop
	LogProcess -Type "log" -Message "Done"

	LogProcess -Type "log" -Message "Installing Sunshine..."
	
	$SunsinePath = "C:\setup\apps\sunshine-windows-installer.exe"

	$exitCode = Start-Process -FilePath $SunsinePath -ArgumentList $exearguments -Wait -PassThru -ErrorAction Stop

	if ($exitCode.ExitCode -eq 0) {
		LogProcess -Type "log" -Message "Sunshine Installation successful!"
	} else {
		LogProcess -Type "log" -Message "Sunshine Installation failed with exit code: $($exitCode.ExitCode)"
	}
	
	LogProcess -Type "log" -Message "------------------------------------------------"
	LogProcess -Type "log" -Message "Copy (Nvidia Driver) 552.44-desktop-win10-win11-64bit-international-dch-whql.exe"
	copy-item "G:\sysprep\apps\552.44-desktop-win10-win11-64bit-international-dch-whql.exe" "c:\setup\apps\552.44-desktop-win10-win11-64bit-international-dch-whql.exe" -force -ErrorAction Stop
	LogProcess -Type "log" -Message "Done"

	# echo "Installing Nvidia..."
	
	# $NvidiaPath = "C:\setup\apps\552.44-desktop-win10-win11-64bit-international-dch-whql.exe"
	# $Nvidiaarguments = "/s quiet /norestart /silent /S"

	# $exitCode = Start-Process -FilePath $NvidiaPath -ArgumentList $Nvidiaarguments -Wait -PassThru -ErrorAction Stop

	# if ($exitCode.ExitCode -eq 0) {
	# 	Write-Host "Nvidia Installation successful!"
	# } else {
	# 	Write-Host "Nvidia Installation failed with exit code: $($exitCode.ExitCode)"
	# }

	LogProcess -Type "log" -Message "Creating Nvidia Driver shortcut..."
	$WshShell = New-Object -comObject WScript.Shell
	$Shortcut = $WshShell.CreateShortcut("c:\Users\admin\Desktop\Nvidia Driver.lnk")
	$Shortcut.TargetPath = "C:\setup\apps\552.44-desktop-win10-win11-64bit-international-dch-whql.exe"
	$Shortcut.Save()
	LogProcess -Type "log" -Message "Done"

	LogProcess -Type "log" -Message "------------------------------------------------"

	# Set script to start at startup
	LogProcess -Type "log" -Message "Creating folder C:\setup\scripts..."
	mkdir "C:\setup\scripts" -ErrorAction Stop
	LogProcess -Type "log" -Message "Copying cloneZeroTierAuto to C:\setup\scripts\..."
	copy-item "G:\sysprep\cloneZeroTierAuto.ps1" "C:\setup\scripts\cloneZeroTierAuto.ps1" -force -ErrorAction Stop
	LogProcess -Type "log" -Message "Done"
	LogProcess -Type "log" -Message "Setting script to start at startup..."
	$scriptPath = "C:\setup\scripts\cloneZeroTierAuto.ps1"
	$shortcutPath = "$([System.Environment]::GetFolderPath('Startup'))\cloneZeroTierAuto.lnk"
	$WshShell = New-Object -ComObject WScript.Shell
	$Shortcut = $WshShell.CreateShortcut($shortcutPath)
	$Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
	$Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -Command `& {Set-Location 'C:\setup\scripts'; . '$scriptPath'} | Out-File -Append -FilePath 'C:\setup\scripts\ZeroTierAuto.log'"
	$Shortcut.Save()
	LogProcess -Type "log" -Message "Done"

	LogProcess -Type "log" -Message "------------------------------------------------"

	LogProcess -Type "log" -Message "Emptying IP Configuration..."
	# Emptying IP Configuration
	ipconfig /release "Ethernet"
	LogProcess -Type "log" -Message "Done"

	LogProcess -Type "log" -Message "------------------------------------------------"

	# echo "Setting script to start at startup..."
	# $scriptPath = "C:\setup\scripts\ZeroTierAuto\controller\vmStart.ps1"
	# $shortcutPath = "$([System.Environment]::GetFolderPath('Startup'))\vmStart.lnk"
	# $WshShell = New-Object -ComObject WScript.Shell
	# $Shortcut = $WshShell.CreateShortcut($shortcutPath)
	# $Shortcut.TargetPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
	# $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -Command `& {Set-Location 'C:\setup\scripts\ZeroTierAuto'; . '$scriptPath'} | Out-File -Append -FilePath 'C:\setup\scripts\ZeroTierAuto\network.log'"
	# $Shortcut.Save()
	# echo "Done"

} catch {
	Write-Output "This is the error...  Error Details: $($_.Exception.Message)"
	LogProcess -Type "log" -Message "------------------------------------------------"
	LogProcess -Type "log" -Message "This is the error...  Error Details: $($_.Exception.Message)"
}
