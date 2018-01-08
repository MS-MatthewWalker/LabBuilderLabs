
#region
# Code from Ben Armstrong https://blogs.msdn.microsoft.com/virtual_pc_guy/2010/09/23/a-self-elevating-powershell-script/ 
# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
 
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole))
   {
   # We are running "as Administrator" - so change the title and background color to indicate this
   $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + "(Elevated)"
   $Host.UI.RawUI.BackgroundColor = "DarkBlue"
   clear-host
   }
else
   {
   # We are not running "as Administrator" - so relaunch as administrator
   
   # Create a new process object that starts PowerShell
   $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";
   
   # Specify the current script path and name as a parameter
   $newProcess.Arguments = $myInvocation.MyCommand.Definition, "$(Get-Location)";
   
   # Indicate that the process should be elevated
   $newProcess.Verb = "runas";
   
   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);
   
   # Exit from the current, unelevated, process
   exit
   }
#endregion 
# Run your code that needs to be elevated here
Set-Location ([System.Environment]::GetCommandLineArgs()[2]);
Write-Host -NoNewLine "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

. .\functions.ps1
. .\DownloadModules.ps1

$Workdir=Get-ScriptDirectory

Write-Host "`t Working directory is $Workdir"

# Get the Configuration 
[xml]$LabsXML = Get-Content ".\Configurations\configurations.xml"
$ChooseLabs = @()
$AvailableLabs = @()
    $AvailableLabs = $LabsXML.Configurations.Configuration
    foreach ($AvailableLab in $AvailableLabs)
		{$ChooseLabs += $AvailableLab.Name }

$Configuration = ShowMenu -Title "Choose Configuration" -Message "Choose the appropriate configuration for the lab you want to build" -ListSource $ChooseLabs

$ConfigFiles = @()
foreach ($AvailableLab in $AvailableLabs)
	{if ($Configuration -eq $Availablelab.Name)
		{ 
			$ConfigFiles += $AvailableLab.LabConfigFile
			$LabConfigFile = $AvailableLab.LabConfigFile
			$AdminAcct = $Availablelab.DomainAdminName
			$AdminPass = $Availablelab.DomainPassword
			if ($Availablelab.HasDC -eq "Yes")
				{
					$ConfigFiles += $AvailableLab.DCConfigurationFile
					$DCConfigFile = $AvailableLab.DCConfigurationFile
				}

            $EnableVBS=$False    
            if ($AvailableLab.RequireVBS -eq "Yes")
                {
                    $EnableVBS=$True
                }

            $EnableSharedDisk=$False    
            if ($AvailableLab.RequireSharedDisk -eq "Yes")
                {
                    $EnableSharedDisk=$True
                }

		}   
	}


# Set Variables for Config Files 


$LABfolderDrivePath=$Workdir.Substring(0,3)
$LABFolder=$LabFolderDrivePath + "LABS"

$LabPath = Read-Host "Please provide path to setup VMs (Default is $LABFolder)"

if ($LabPath)
	{
		Write-Host "You specified path $LabPath"
		$LabFolder = $LabPath
	}

Write-Host "`t LabFolder is $LabFolder"

ForEach ($ConfigFile in $ConfigFiles)
{
	[xml]$ConfigXML = Get-Content "$Workdir\Configurations\$ConfigFile"

    [string]$LabID = $ConfigXML.labbuilderconfig.settings.LabId

	[string]$XMLResourcePath = $ConfigXML.labbuilderconfig.settings.resourcepath
	[string]$XMLModulePath = $ConfigXML.labbuilderconfig.settings.modulepath
	[string]$XMLDSCPath = $ConfigXML.labbuilderconfig.settings.dsclibrarypath
	[string]$XMLVHDParentPath = $ConfigXML.labbuildconfig.settings.vhdparentpath
	$Resources = $ConfigXML.labbuilderconfig.resources.msu

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

	   if ($XMLVHDParentPath) {
        if (-not [System.IO.Path]::IsPathRooted($XMLVHDParentPath))
        {
            # A relative path was provided in the VHD Parent path so add the actual path of the
            # folder to it
            [String] $FullVHDParentPath = Join-Path `
                -Path $Workdir `
                -ChildPath $XMLVHDParentPath

			$ConfigXML.labbuilderconfig.settings.vhdparentpath = $FullVHDParentPath
        } # if
    }

If ($EnableSharedDisk)
    {
        $SharedDiskPath="$LabFolder\Shared"
        $VMs = $ConfigXML.labbuilderconfig.vms.vm
        
        ForEach ($VM in $VMs)
        {
            if ($VM.DataVHDs.DataVHD.Shared -eq 'Y')
            {
                $DataVHDs = $VM.DataVHDs.DataVHD
                foreach ($DataVHD in $DataVHDs)
                {
                    if ($DataVHD.Shared -eq 'Y')
                    {
                        [String] $DataVHDPath = $DataVHD.VHD
                        $DataVHDPath = $DataVHDPath.Replace('SharedPath', $SharedDiskPath)
                        $DataVHD.VHD = $DataVHDPath
                        $ConfigXML.Save("$Workdir\Configurations\$ConfigFile")
                    } #IF
                } #ForEach
            } #IF

        } #ForEach
     } #IF

    $ToolsPath = "$Workdir\Tools"
    $VMs = $ConfigXML.labbuilderconfig.vms.vm
         
    ForEach ($VM in $VMs) {
        $DataVHDs = $VM.DataVHDs.DataVHD
        foreach ($DataVHD in $DataVHDs) {
            if ($DataVHD.copyfolders) {
                [String] $DataToolsPath = $DataVHD.copyfolders
                $DataToolsPath = $DataToolsPath.Replace('ToolsPath', $ToolsPath)
                $DataVHD.copyfolders = $DataToolsPath
                $ConfigXML.Save("$Workdir\Configurations\$ConfigFile")
            } #IF
        } #ForEach
 
    } #ForEach
 

    $ODJFilePath = $WorkDir
    $VMs = $ConfigXML.labbuilderconfig.vms.vm
        
    ForEach ($VM in $VMs) {
        if ($VM.NanoODJPath) {
            [String] $NanoODJPath = $VM.NanoODJPath
            $NanoODJPath = $NanoODJPath.Replace('ODJPath', $ODJFilePath)
            $VM.NanoODJPath = $NanoODJPath
            $ConfigXML.Save("$Workdir\Configurations\$ConfigFile")
        } #IF
    } #ForEach



Foreach ($msu in $Resources)
		{
        if (($msu.url).StartsWith('ResFolder'))
        {
            # Convert File path to local directory path 
            [String] $ResPath = $msu.url 
            $ResPath = $ResPath.replace('ResFolder',"file:///$Workdir/resources")
            $ResPath = $ResPath.Replace('\','/')
            $msu.url = $ResPath
			$ConfigXML.Save("$Workdir\Configurations\$ConfigFile")
        } # if
    }


$ConfigXML.Save("$Workdir\Configurations\$ConfigFile")
}

#Check if Hyper-V is installed.
Write-Host "Checking if Hyper-V is installed" -ForegroundColor Cyan
if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V).state -eq 'Enabled')
    {
	Write-Host "`t Hyper-V is Installed" -ForegroundColor Green
    }
    else    
    {
	Write-Host "`t Hyper-V not installed. Installing Hyper-V and tools - after reboot re-run script" -ForegroundColor Red
        $OS=Get-CimInstance -ClassName win32_operatingsystem 
        if ((($OS.operatingsystemsku -eq 7) -or ($OS.operatingsystemsku -eq 8) -or ($OS.operatingsystemsku -eq 79) -or ($OS.operatingsystemsku -eq 80)) -and $OS.version -gt 10)
            {	
                Install-WindowsFeature -Name Hyper-V -IncludeManagementTools -Restart
                Write-Host "Press any key to continue ..."
                $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | OUT-NULL
                $HOST.UI.RawUI.Flushinputbuffer()
                Exit
            }

            elseif ((($OS.operatingsystemsku -eq 4) -or ($OS.operatingsystemsku -eq 6) -and $OS.version -gt 10))
            {
                Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
            }
    }

# Check for Support for Vitualization based Security - enable if necessary 
    If ($EnableVBS)
        {
            $DevGuard = Get-CimInstance –ClassName Win32_DeviceGuard –Namespace root\Microsoft\Windows\DeviceGuard
            if (-not(($DevGuard.SecurityServicesConfigured -contains 1)-or ($DevGuard.SecurityServicesConfigured -contains 2))) 
                {
                    New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard -Force  
                    New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard -Name EnableVirtualizationBasedSecurity -Value 1 -PropertyType DWord -Force

                }
                else    {"Credential Guard configured"}
            if (-Not($DevGuard.VirtualizationBasedSecurityStatus -contains 2))
                {
                    Write-Host "Virtualization Based Security is not running - if this is a Nested VM, set VirtualizationBasedSecurityOptOut to False. If this is a physical host you will need to troubleshoot" -ForegroundColor Red
                }
                
                else {"Credential Guard running"}

 
    
        }



# Check support for shared disks + enable if possible - Operating SKU versions are from header files and reported by WMI - 7 = Standard, 8 = DataCenter, 79 Standard Eval, and 80 is DataCenter Eval

    If ($EnableSharedDisk)
    {
        

        Write-Host "Checking for support for shared disks" -ForegroundColor Cyan
        $OS=Get-WmiObject win32_operatingsystem
        if ((($OS.operatingsystemsku -eq 7) -or ($OS.operatingsystemsku -eq 8) -or ($OS.operatingsystemsku -eq 79) -or ($OS.operatingsystemsku -eq 80)) -and $OS.version -gt 10)
        {
            Write-Host "`t Installing Failover Clustering Feature"
            $FC=Install-WindowsFeature Failover-Clustering 

                Write-Host "Attaching svhdxflt filter driver to drive $LABfolderDrivePath" -ForegroundColor Cyan

                fltmc.exe attach svhdxflt $LABfolderDrivePath

                Write-Host "Adding svhdxflt to registry for autostart" -ForegroundColor Cyan
                
                if (-not(Test-Path HKLM:\SYSTEM\CurrentControlSet\Services\svhdxflt\Parameters))
                {
                    New-Item HKLM:\SYSTEM\CurrentControlSet\Services\svhdxflt\Parameters
                }
                
                New-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\svhdxflt\Parameters -Name AutoAttachOnNonCSVVolumes -PropertyType DWORD -Value 1 -force


            If ($FC.Success -eq $True)
            {
                Write-Host "`t`t Failover Clustering Feature installed with exit code: "$FC.ExitCode 
            }
            else
            {
                Write-Host "`t`t Failover Clustering Feature was not installed with exit code: "$FC.ExitCode
            }

        }
    }

#Mount ISO and copy out .Net Cab file for SQL install

$ISOPath = "$Workdir\Configurations\ISOFiles\14393.0.161119-1705.RS1_REFRESH_SERVER_EVAL_X64FRE_EN-US.ISO"

$null = Mount-DiskImage -ImagePath $ISOPath -StorageType ISO -Access Readonly

# Refresh the PS Drive list to make sure the new drive can be detected
$null = Get-PSDrive -PSProvider FileSystem

$DiskImage = Get-DiskImage -ImagePath $ISOPath
$Volume = Get-Volume -DiskImage $DiskImage
        
[String] $DriveLetter = $Volume.DriveLetter
[String] $ISODrive = "$([string]$DriveLetter):"

Copy-Item -Path $ISODrive\Sources\SXS\microsoft-windows-netfx3-ondemand-package.cab -Destination $Workdir\Tools\Files\microsoft-windows-netfx3-ondemand-package.cab -Force

$null = Dismount-DiskImage -ImagePath $ISOPath

# Now Copy the Windows Server ISO file

Copy-Item -Path $ISOPath -Destination $Workdir\Tools\ISOs\14393.0.160715-1616.RS1_RELEASE_SERVER_EVAL_X64FRE_EN-US.ISO -Force

If ($DCConfigFile)
    {
        Import-Module .\LabBuilder.psm1 -Force
        Install-Lab -ConfigPath $Workdir\Configurations\$DCConfigFile -labpath $LABfolder -Verbose -Offline

        $VMStartupTime = 300 
        Write-host "Configuring DC takes a while"
        Write-host "Initial configuration in progress. Sleeping $VMStartupTime seconds"
        Start-Sleep $VMStartupTime

        $DCVM = Get-VM -Name "$LabId*"

        [PSCredential]$Cred = New-Object System.Management.Automation.PSCredential ($AdminAcct, (ConvertTo-SecureString $AdminPass -AsPlainText -Force))

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

        $Session = New-PSSession -VMname $DCVM.VMName -Credential $Cred
        Copy-Item -FromSession $Session -Path T:\Tools\ODJFiles -Recurse -Destination $Workdir\Tools\ -Force
    }

Import-Module .\LabBuilder.psm1 -Force
Install-Lab -ConfigPath $Workdir\Configurations\$LabConfigFile -labpath $LABfolder -Verbose -Offline
