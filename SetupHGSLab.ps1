# Verify Running as Admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
If (!( $isAdmin )) {
	Write-Host "-- Restarting as Administrator" -ForegroundColor Cyan ; Sleep -Seconds 1
	Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs 
	exit
}

##########################################################################################

Function Get-ScriptDirectory
    {
    Split-Path $script:MyInvocation.MyCommand.Path
    }

##########################################################################################

$ISOName = "14393.0.160715-1616.RS1_RELEASE_SERVER_EVAL_X64FRE_EN-US.ISO"

$Workdir=Get-ScriptDirectory

Write-Host "`t Working directory is $Workdir"

$LABfolderDrivePath=$Workdir.Substring(0,3)
$LABFolder="$LabFolderDrivePath\LABS"
Write-Host "`t LabFolder is $LabFolder"

$ConfigFiles = @()
$ConfigFiles += 'SVM-DC-Lab-Setup-Config.xml'
$ConfigFiles += 'SVM-Lab-Setup-Config.xml'
$DCConfigFile = 'SVM-DC-Lab-Setup-Config.xml'
$LabConfigFile = 'SVM-Lab-Setup-Config.xml'

ForEach ($ConfigFile in $ConfigFiles)
{
	[xml]$ConfigXML = Get-Content "$Workdir\Configurations\$ConfigFile"

	[string]$XMLResourcePath = $ConfigXML.labbuilderconfig.settings.resourcepath
	[string]$XMLModulePath = $ConfigXML.labbuilderconfig.settings.modulepath
	[string]$XMLDSCPath = $ConfigXML.labbuilderconfig.settings.dsclibrarypath

	   if ($XMLResourcePath) {
        if (-not [System.IO.Path]::IsPathRooted($XMLResourcePath))
        {
            # A relative path was provided in the Resource path so add the actual path of the
            # folder to it
            [String] $FullResourcePath = Join-Path `
                -Path $Workdir `
                -ChildPath $XMLResourcePath

			$ConfigXML.labbuilderconfig.settings.resourcepath = $FullResourcePath
        } # if
    }

	   if ($XMLModulePath) {
        if (-not [System.IO.Path]::IsPathRooted($XMLModulePath))
        {
            # A relative path was provided in the Module path so add the actual path of the
            # folder to it
            [String] $FullModulePath = Join-Path `
                -Path $Workdir `
                -ChildPath $XMLModulePath

			$ConfigXML.labbuilderconfig.settings.modulepath = $FullModulePath
        } # if

	  [string]$LabID = $ConfigXML.labbuilderconfig.settings.LabId
    }

	   if ($XMLDSCPath) {
        if (-not [System.IO.Path]::IsPathRooted($XMLDSCPath))
        {
            # A relative path was provided in the DSC path so add the actual path of the
            # folder to it
            [String] $FullDSCPath = Join-Path `
                -Path $Workdir `
                -ChildPath $XMLDSCPath

			$ConfigXML.labbuilderconfig.settings.dsclibrarypath = $FullDSCPath
        } # if
    }
$ConfigXML.Save("$Workdir\Configurations\$ConfigFile")
}

#Check if Hyper-V is installed.
Write-Host "Checking if Hyper-V is installed" -ForegroundColor Cyan
if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V).state -eq 'Enabled'){
	Write-Host "`t Hyper-V is Installed" -ForegroundColor Green
}else{
	Write-Host "`t Hyper-V not installed. Please install hyper-v feature including Hyper-V management tools. Exiting" -ForegroundColor Red
	Write-Host "Press any key to continue ..."
	$host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL
	$HOST.UI.RawUI.Flushinputbuffer()
	Exit
}

#Check support for shared disks + enable if possible - Operating SKU versions are from header files and reported by WMI - 7 = Standard, 8 = DataCenter, 79 Standard Eval, and 80 is DataCenter Eval

    Write-Host "Checking for support for shared disks" -ForegroundColor Cyan
    $OS=gwmi win32_operatingsystem
	if ((($OS.operatingsystemsku -eq 7) -or ($OS.operatingsystemsku -eq 8) -or ($OS.operatingsystemsku -eq 79) -or ($OS.operatingsystemsku -eq 80)) -and $OS.version -gt 10){
		Write-Host "`t Installing Failover Clustering Feature"
		$FC=Install-WindowsFeature Failover-Clustering 

			Write-Host "Attaching svhdxflt filter driver to drive $LABfolderDrivePath" -ForegroundColor Cyan

			fltmc.exe attach svhdxflt $LABfolderDrivePath

			Write-Host "Adding svhdxflt to registry for autostart" -ForegroundColor Cyan
			
			if (!(Test-Path HKLM:\SYSTEM\CurrentControlSet\Services\svhdxflt\Parameters)){
				New-Item HKLM:\SYSTEM\CurrentControlSet\Services\svhdxflt\Parameters
			}
			
			New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\svhdxflt\Parameters -Name AutoAttachOnNonCSVVolumes -PropertyType DWORD -Value 1 -force


		If ($FC.Success -eq $True){
			Write-Host "`t`t Failover Clustering Feature installed with exit code: "$FC.ExitCode 
		}else{
			Write-Host "`t`t Failover Clustering Feature was not installed with exit code: "$FC.ExitCode
		}

	}

Write-Host "`t`t Copying .Net for SQL and ISO for use in VM"
#Mount ISO and copy out .Net Cab file for SQL install

$ISOPath = "$Workdir\Configurations\ISOFiles\$ISOName"

$null = Mount-DiskImage -ImagePath $ISOPath -StorageType ISO -Access Readonly

# Refresh the PS Drive list to make sure the new drive can be detected
$null = Get-PSDrive -PSProvider FileSystem

$DiskImage = Get-DiskImage -ImagePath $ISOPath
$Volume = Get-Volume -DiskImage $DiskImage
        
[String] $DriveLetter = $Volume.DriveLetter
[String] $ISODrive = "$([string]$DriveLetter):"
 
[String] $ToolsPath = "$Workdir\Tools"

Copy-Item -Path $ISODrive\Sources\SXS\microsoft-windows-netfx3-ondemand-package.cab -Destination $ToolsPath\Files\microsoft-windows-netfx3-ondemand-package.cab -Force

$null = Dismount-DiskImage -ImagePath $ISOPath

# Now Copy the Windows Server ISO file

Copy-Item -Path $ISOPath -Destination $ToolsPath\ISOs\$ISOName -Force
Import-Module .\LabBuilder.psm1 -Force
Install-Lab -ConfigPath $Workdir\Configurations\$DCConfigFile -labpath $LABfolder -Verbose -Offline

$VMStartupTime = 300 
Write-host "Configuring DC takes a while"
Write-host "Initial configuration in progress. Sleeping $VMStartupTime seconds"
Start-Sleep $VMStartupTime

$DCVM = Get-VM -Name "$LabId*"

[PSCredential]$Cred = New-Object System.Management.Automation.PSCredential ('Contoso\Administrator', (ConvertTo-SecureString 'Password1' -AsPlainText -Force))

do{
	$test=Invoke-Command -VMGuid $DCVM.id -ScriptBlock {Get-DscConfigurationStatus} -Credential $cred -ErrorAction SilentlyContinue
	if ($test -eq $null) {
		Write-Host "Configuration in Progress. Sleeping 10 seconds"
	}else{
		Write-Host "Current DSC state: $($test.status), ResourcesNotInDesiredState: $($test.resourcesNotInDesiredState.count), ResourcesInDesiredState: $($test.resourcesInDesiredState.count). Sleeping 10 seconds" 
		Write-Host "Invoking DSC Configuration again" 
		Invoke-Command -VMGuid $DCVM.id -ScriptBlock {Start-DscConfiguration -UseExisting} -Credential $cred
	}
	Start-Sleep 10
}until ($test.Status -eq 'Success' -and $test.rebootrequested -eq $false)
$test


Import-Module .\LabBuilder.psm1 -Force
Install-Lab -ConfigPath $Workdir\Configurations\$LabConfigFile -labpath $LABfolder -Verbose -Offline
