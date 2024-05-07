try {
	# Setup app installation
	echo "Copy all app"
	mkdir "c:\setup\app" -ErrorAction Stop
	# copy-item "G:\sysprep\app" "c:\setup\app" -force -ErrorAction Stop
	echo "Done"

	Start-Sleep 15
	echo "------------------------------------------------"
	echo "Copy Cloudflare_WARP_2024.3.409.0.msi"
	copy-item "G:\sysprep\app\Cloudflare_WARP_2024.3.409.0.msi" "c:\setup\app\Cloudflare_WARP_2024.3.409.0.msi" -force -ErrorAction Stop
	echo "Done"

	echo "Installing CloudFlare..."
	$CFPath = "C:\setup\app\Cloudflare_WARP_2024.3.409.0.msi"
	$msiarguments = "/quiet /norestart"
	$exitCode = Start-Process -FilePath $CFPath -ArgumentList $msiarguments -Wait -PassThru -ErrorAction Stop

	# Check installation status
	if ($exitCode.ExitCode -eq 0) {
		Write-Host "CloudFlare Installation successful!"
	} else {
		Write-Host "CloudFlare Installation failed with exit code: $($exitCode.ExitCode)"
	}

	Start-Sleep 5
	echo "------------------------------------------------"
        echo "Copy ZeroTier One.msi"
        copy-item "G:\sysprep\app\ZeroTier One.msi" "c:\setup\app\ZeroTier One.msi" -force -ErrorAction Stop
        echo "Done"

	echo "Installing ZeroTier..."
	
	$ZTPath = "C:\setup\app\ZeroTier One.msi"
	$exitCode = Start-Process -FilePath $ZTPath -ArgumentList $msiarguments -Wait -PassThru -ErrorAction Stop

	if ($exitCode.ExitCode -eq 0) {
		Write-Host "ZeroTier Installation successful!"
	} else {
		Write-Host "ZeroTier Installation failed with exit code: $($exitCode.ExitCode)"
	}

	Start-Sleep 5
	echo "------------------------------------------------"
        echo "Copy SteamSetup.exe"
        copy-item "G:\sysprep\app\SteamSetup.exe" "c:\setup\app\SteamSetup.exe" -force -ErrorAction Stop
        echo "Done"

	echo "Installing Steam..."
	
	$SteamPath = "C:\setup\app\SteamSetup.exe"
	$exearguments = "/quiet /norestart /silent /S"

	$exitCode = Start-Process -FilePath $SteamPath -ArgumentList $exearguments -Wait -PassThru -ErrorAction Stop

	if ($exitCode.ExitCode -eq 0) {
		Write-Host "Steam Installation successful!"
	} else {
		Write-Host "Steam Installation failed with exit code: $($exitCode.ExitCode)"
	}

	Start-Sleep 5
	echo "------------------------------------------------"
        echo "Copy sunshine-windows-installer.exe"
        copy-item "G:\sysprep\app\sunshine-windows-installer.exe" "c:\setup\app\sunshine-windows-installer.exe" -force -ErrorAction Stop
        echo "Done"

	echo "Installing Sunshine..."
	
	$SunsinePath = "C:\setup\app\sunshine-windows-installer.exe"

	$exitCode = Start-Process -FilePath $SunsinePath -ArgumentList $exearguments -Wait -PassThru -ErrorAction Stop

	if ($exitCode.ExitCode -eq 0) {
		Write-Host "Sunshine Installation successful!"
	} else {
		Write-Host "Sunshine Installation failed with exit code: $($exitCode.ExitCode)"
	}
	
	Start-Sleep 5
	echo "------------------------------------------------"
	echo "Copy Nvidia Driver"
	copy-item "G:\sysprep\app\552.22-desktop-win10-win11-64bit-international-dch-whql.exe" "c:\setup\app\552.22-desktop-win10-win11-64bit-international-dch-whql.exe" -force -ErrorAction Stop
	echo "Done"

	# echo "Installing Nvidia..."
	
	# $NvidiaPath = "C:\setup\app\552.22-desktop-win10-win11-64bit-international-dch-whql.exe"
	# $Nvidiaarguments = "/s quiet /norestart /silent /S"

	# $exitCode = Start-Process -FilePath $NvidiaPath -ArgumentList $Nvidiaarguments -Wait -PassThru -ErrorAction Stop

	# if ($exitCode.ExitCode -eq 0) {
	# 	Write-Host "Nvidia Installation successful!"
	# } else {
	# 	Write-Host "Nvidia Installation failed with exit code: $($exitCode.ExitCode)"
	# }

	echo "Creating Shortcut for Nvidia Driver"
	$WshShell = New-Object -comObject WScript.Shell
	$Shortcut = $WshShell.CreateShortcut("c:\Users\admin\Desktop\Nvidia Driver.lnk")
	$Shortcut.TargetPath = "C:\setup\app\552.22-desktop-win10-win11-64bit-international-dch-whql.exe"
	$Shortcut.Save()

	echo "------------------------------------------------"
	
	# Check for admin privileges
	if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
		Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
		Break
	}

	echo "Installing Scoop..."
	echo "Setting PS execution policy..."
	# Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
	echo "Done"
	try {
			Invoke-RestMethod -Uri https://get.scoop.sh -OutFile 'c:\setup\app\install.ps1'
			& 'c:\setup\app\install.ps1' -RunAsAdmin | Out-Null
			if ($LASTEXITCODE -eq 0) {
					echo "Scoop installation successful!"
			} else {
					throw "Scoop installation failed with exit code: $LASTEXITCODE"
			}
	} catch {
			echo "Scoop installation failed with error: $_"
	}
	echo "------------------------------------------------"

	echo "Installing Git..."
	try {
			scoop install git
			echo "Git installation successful!"
	} catch {
			echo "Git installation failed with error: $_"
	}

	echo "------------------------------------------------"

	echo "Installing IddSampleDriver..."
	try {
	    scoop bucket add extras
	    scoop bucket add nonportable
	    scoop install iddsampledriver-ge9-np -g
	    echo "IddSampleDriver installation successful!"
	} catch {
	    echo "IddSampleDriver installation failed with error: $_"
	}

	echo "------------------------------------------------"

	echo "Editing C:\IddSampleDriver\option.txt..."
	$content = Get-Content -Path "C:\IddSampleDriver\option.txt"
	$content[0] = "2"
	$content | Set-Content -Path "C:\IddSampleDriver\option.txt"
	echo "Done"

	echo "------------------------------------------------"

	echo "Restarting IddSampleDriver Device..."
	$deviceId = (Get-PnpDevice | Where-Object { $_.FriendlyName -eq "IddSampleDriver Device" }).InstanceId
	Disable-PnpDevice -InstanceId $deviceId -Confirm:$false
	Enable-PnpDevice -InstanceId $deviceId -Confirm:$false
	echo "Done"

	echo "------------------------------------------------"

	echo "Cloning network configuration dependencies..."
	git clone https://github.com/JordanSihombing/ZeroTierAuto.git "C:\setup\scripts\ZeroTierAuto"
	echo "Done"

} catch {
	Write-Output "This is the error...  Error Details: $($_.Exception.Message)"
	echo "------------------------------------------------"
}
