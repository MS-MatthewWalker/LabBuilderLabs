<#########################################################################################################################################
DSC Template Configuration File For use by LabBuilder
.Title
    DC_FORESTPRIMARY
.Desription
    Builds a Domain Controller as the first DC in a forest with the name of the Domain Name parameter passed.
.Parameters:          
    DomainName = "LABBUILDER.COM"
    DomainAdminPassword = "P@ssword!1"
#########################################################################################################################################>

Configuration LAB_DC_FORESTPRIMARY
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration' 
    Import-DscResource -ModuleName xDNSServer 
	Import-DscResource -ModuleName xDHCPServer 
	Import-DscResource -ModuleName ciscsi 
	Import-DscResource -ModuleName xStorage 
    Import-DscResource -ModuleName xActiveDirectory
    Import-DscResource -ModuleName xHyper-V
    Import-DscResource -ModuleName xSMBShare
    Import-DscResource -ModuleName xSCVMM
    Import-DscResource -ModuleName SQLServerDsc


    Node $AllNodes.NodeName {

       

        # Assemble the Local Admin Credentials
        If ($Node.LocalAdminPassword) {
            [PSCredential]$LocalAdminCredential = New-Object System.Management.Automation.PSCredential ("Administrator", (ConvertTo-SecureString $Node.LocalAdminPassword -AsPlainText -Force))
        }
        If ($Node.DomainAdminPassword) {
            [PSCredential]$DomainAdminCredential = New-Object System.Management.Automation.PSCredential ("Administrator", (ConvertTo-SecureString $Node.DomainAdminPassword -AsPlainText -Force))
        }
         
        If ($Node.ADuserPass) {
            [PSCredential]$ADUserCred = New-Object System.Management.Automation.PSCredential ($Node.ADUser, (ConvertTo-SecureString $Node.ADUserpass -AsPlainText -Force))
        }
# Only Needed for VMM environments 
        If ($Node.SQLSAUser) {
            [PSCredential]$SQLSA = New-Object System.Management.Automation.PSCredential ($Node.SQLSAUser, (ConvertTo-SecureString $Node.SQLSAUserPass -AsPlainText -Force))
        }
  
        If ($Node.SQLAgentUser) {
            [PSCredential]$SQLAgentSA = New-Object System.Management.Automation.PSCredential ($Node.SQLAgentUser, (ConvertTo-SecureString $Node.SQLAgentUserPass -AsPlainText -Force))
        }

        If ($Node.SCVMMSAUser) {
            [PSCredential]$SCVMMSA = New-Object System.Management.Automation.PSCredential ($Node.SCVMMSAUser, (ConvertTo-SecureString $Node.SCVMMSAPass -AsPlainText -Force))
        }


        WindowsFeature NET
        {
            Ensure = "Present" 
            Name = "NET-Framework-Core"
            Source = 't:\tools\files' 
            DependsOn = "[xDisk]ToolsDrive"
        }
# End of VMM environment  
        WindowsFeature FailoverClusteringPSInstall
        {
            Ensure = "Present" 
            Name = "RSAT-Clustering-PowerShell" 
        }

        WindowsFeature FailoverClusteringManagerInstall
        {
            Ensure = "Present" 
            Name = "RSAT-Clustering-MGMT" 
        }

        WindowsFeature FileServerInstall 
        {
            Ensure = "Present" 
            Name = "FS-FileServer" 
            DependsOn = "[WindowsFeature]FailoverClusteringPSInstall" 
        }


        WindowsFeature DHCPInstall 
        { 
            Ensure = "Present" 
            Name = "DHCP" 
        }
        
		WindowsFeature UpdateServicesWIDDBInstall 
        { 
            Ensure = "Present" 
            Name = "UpdateServices-WidDB" 
        } 

		WindowsFeature UpdateServicesServicesInstall 
        { 
            Ensure = "Present" 
            Name = "UpdateServices-Services" 
			DependsOn = "[WindowsFeature]UpdateServicesWIDDBInstall" 
        }

		WindowsFeature UpdateServicesAPI 
        { 
            Ensure = "Present" 
            Name = "UpdateServices-API" 
			DependsOn = "[WindowsFeature]UpdateServicesWIDDBInstall" 
        } 

		WindowsFeature UpdateServicesUI 
        { 
            Ensure = "Present" 
            Name = "UpdateServices-UI" 
			DependsOn = "[WindowsFeature]UpdateServicesWIDDBInstall" 
        }
                
        WindowsFeature RSAT-DHCPInstall 
        { 
            Ensure = "Present" 
            Name = "RSAT-DHCP" 
        }

        WindowsFeature DNSInstall 
        { 
            Ensure = "Present" 
            Name = "DNS" 
		} 

        WindowsFeature iSCSITargetServerInstall 
        { 
            Ensure = "Present" 
            Name = "FS-iSCSITarget-Server" 
        }

        WindowsFeature ADDSInstall 
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services" 
            DependsOn = "[WindowsFeature]DNSInstall" 
        } 
        
        WindowsFeature RSAT-AD-PowerShellInstall
        {
            Ensure = "Present"
            Name = "RSAT-AD-PowerShell"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }
        WindowsFeature FeatureGPMC
        {
            Ensure = "Present"
            Name = "GPMC"
            DependsOn = "[WindowsFeature]ADDSInstall"
        } 

        WindowsFeature FeatureADAdminCenter
        {
            Ensure = "Present"
            Name = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSInstall"
        } 

        WindowsFeature FeatureADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        } 

        WindowsFeature FeatureDNSTools
        {
            Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]ADDSInstall"
        } 

        WindowsFeature RSAT-Hyper-VPowerShellInstall 
        { 
           Ensure = "Present" 
           Name = "Hyper-V-PowerShell"
        }
        
        WindowsFeature RSAT-Hyper-VGUIInstall 
        { 
           Ensure = "Present" 
           Name = "Hyper-V-Tools"
        }
		
		xWaitForDisk WaitiSCSIDrive
		{
			DiskId = "2"
			RetryIntervalSec = "5"
			RetryCount = "10"
		}
		
		xDisk iSCSIDrive
		{
			DiskId ='2'
			DriveLetter = 'I'
			FSLabel = 'iSCSI'
		}
        
		xDisk ToolsDrive
		{
			DiskId ="1"
			DriveLetter = "T"
        }
        
        xWaitForDisk WaitToolsDrive
		{
			DiskId = "1"
			RetryIntervalSec = "5"
			RetryCount = "10"
		}

        xSmbShare HelpSMBShare
        {
            Ensure = "Present" 
            Name   = "PowerShellHelp"
            Path = "T:\Tools\Help"  
            FullAccess = "Authenticated Users"
            Description = "Updated PowerShell Help Files"
            DependsOn = "[xDisk]ToolsDrive"
        }

        xSmbShare ISOSMBShare
        {
            Ensure = "Present" 
            Name   = "ISOs"
            Path = "T:\Tools\ISOs"  
            FullAccess = "Authenticated Users"
            Description = "File Share for ISOs"
            DependsOn = "[xDisk]ToolsDrive"
        } 

		xADDomain PrimaryDC 
        { 
            DomainName = $Node.DomainName 
            DomainAdministratorCredential = $DomainAdminCredential 
            SafemodeAdministratorPassword = $LocalAdminCredential
            DependsOn = "[WindowsFeature]ADDSInstall" 
        } 

        xWaitForADDomain DscForestWait 
        { 
            DomainName = $Node.DomainName 
            DomainUserCredential = $DomainAdminCredential 
            RetryCount = 20 
            RetryIntervalSec = 30 
            DependsOn = "[xADDomain]PrimaryDC" 
        } 

       [Int]$Count=0
       Foreach ($NanoServer in $Node.NanoServers){    
            $Count++
            $ODJName = "$($NanoServer.ComputerName)"
            $RequestFile = "$($NanoServer.FilePath)" + "$($NanoServer.ComputerName)" + ".txt"
                xADComputer "$ODJname"
                {
                DomainAdministratorCredential = $DomainAdminCredential
                ComputerName = $ODJName
                RequestFile =  $RequestFile
                DependsOn = "[Script]SetDefaultOUComputer"
                }
        }

# VMM requirements 
        # Install prerequisites on Management Servers
        $BasePath = $Node.ToolsPath

        $WindowsADK = '\Files\ADK\adksetup.exe'

        Package "WindowsDeploymentTools"
        {
            Ensure = "Present"
            Name = "Windows Deployment Tools"
            ProductId = ""
            Path = "$Basepath$WindowsADK"
            Arguments = "/quiet /features OptionId.DeploymentTools"
            Credential = $DomainAdminCredential
            DependsOn = "[xDisk]ToolsDrive"
        }

        Package "WindowsPreinstallationEnvironment"
        {
            Ensure = "Present"
            Name = "Windows PE x86 x64"
            ProductId = ""
            Path = "$Basepath$WindowsADK"
            Arguments = "/quiet /features OptionId.WindowsPreinstallationEnvironment"
            Credential = $DomainAdminCredential
            DependsOn = "[xDisk]ToolsDrive"                
        }

        SqlSetup SCVMMSQLDB
        {
            DependsOn = "[WindowsFeature]NET"
            SourcePath = $Node.SQLSourcePath
            PSDscRunAsCredential = $DomainAdminCredential
            InstanceName = $Node.SQLInstanceName
            Features = $Node.SQLFeatures
            SQLSVCAccount = $SQLSA
            SQLSysAdminAccounts = $Node.SQLSysAdminAccounts
            AgtSvcAccount = $SQLAgentSA
        }


        xSCVMMManagementServerSetup "VMMMS"
        {
            DependsOn = "[xSCVMMConsoleSetup]VMMC"
            Ensure = "Present"
            SourcePath = $BasePath
            SourceFolder = $Node.SCVMMInstallPath
            SetupCredential = $DomainAdminCredential
            vmmService = $SCVMMSA
            SqlMachineName = $Node.SCVMMDBServerName
            SqlInstanceName = $Node.SQLInstanceName
        }

        xSCVMMConsoleSetup "VMMC"
        {
            DependsOn = "[SqlSetup]SCVMMSQLDB"
            Ensure = "Present"
            SourcePath =  $BasePath
            SourceFolder = $Node.SCVMMInstallPath
            SetupCredential = $DomainAdminCredential
        }
  # End Only Needed for VMM environments 

       [Int]$Count=0
       Foreach ($ADOU in $Node.ADOUs){    
            $Count++
            $ResName = "$($ADOU.Name)"
            xADOrganizationalUnit "Add$ResName"
            {
                Name = $ResName
                Path = $ADOU.Path
                ProtectedFromAccidentalDeletion = $true
                Description = $ADOU.Description
                Ensure = 'Present'
                DependsOn = "[xADDomain]PrimaryDC" 
            }
        }

       [Int]$Count=0
       Foreach ($ADUser in $Node.ADUsers){    
            $Count++
            $ResName = "$($Aduser.Name)"
            [PSCredential]$ADUserCred = New-Object System.Management.Automation.PSCredential ($Aduser.Name, (ConvertTo-SecureString $ADUser.Cred -AsPlainText -Force))
            xADUser "Add$ResName" 
            {
                DomainName = $Node.DomainName
                DomainAdministratorCredential = $DomainAdminCredential
                UserName = $ResName
                Password = $ADUserCred
                Ensure = "Present"
                Description = $ADUser.Description
                PasswordNeverExpires = $true
                DependsOn = "[Script]SetDefaultOUUser"
            } # End of ADUsers Resource
        }

       $Admins = @()
       Foreach ($ADUser in $Node.ADUsers)
       { 
           $Admins += $ADuser.Name
       }


        $ADGroupName = 'Domain Admins'
        xADGroup "ADDADuserAdmin" 
        {
            GroupName = $ADGroupName
            DependsOn = '[Script]SetDefaultOUUser'
            MembersToInclude = $Admins
            Credential = $DomainAdminCredential
        } # End of ADUsers Resource

		xADUser AdministratorNeverExpires
        {
            DomainName = $Node.DomainName
			UserName = "Administrator"
            Ensure = "Present"
            DependsOn = "[xADDomain]PrimaryDC"
			PasswordNeverExpires = $true
	    }
        
        # Enable AD Recycle bin
        xADRecycleBin RecycleBin
        {
            EnterpriseAdministratorCredential = $DomainAdminCredential
            ForestFQDN = $Node.DomainName
            DependsOn = "[xWaitForADDomain]DscForestWait"
        }

        # Install a KDS Root Key so we can create MSA/gMSA accounts
        Script CreateKDSRootKey
        {
            SetScript = {
                Add-KDSRootKey -EffectiveTime ((Get-Date).AddHours(-10))			}
            GetScript = {
                Return @{
                    $KDSRootKey = (Get-KDSRootKey)
                }
            }
            TestScript = { 
                If (-not (Get-KDSRootKey)) {
                    Write-Verbose "KDS Root Key Needs to be installed..."
                    Return $False
                }
                Return $True
            }
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        # Authorize DHCP server 
		 Script DHCPAuthorize
        {
            PSDSCRunAsCredential = $DomainAdminCredential
            SetScript = {
                Add-DHCPServerInDC
            }
            GetScript = {
                Return @{
                    'Authorized' = (@(Get-DHCPServerInDC | Where-Object { $_.IPAddress -In (Get-NetIPAddress).IPAddress }).Count -gt 0);
                }
            }
            TestScript = { 
                Return (-not (@(Get-DHCPServerInDC | Where-Object { $_.IPAddress -In (Get-NetIPAddress).IPAddress }).Count -eq 0))
            }
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

        # Set Default OUs
		 Script SetDefaultOUComputer
        {
            PSDSCRunAsCredential = $DomainAdminCredential
            SetScript = { 
                redircmp $($Using:Node.ADDefaultComputersOU)
            }
            GetScript = {
                Return @{
                    'CurrentOU' = (Get-ADDomain).ComputersContainer;
                }
            }
            TestScript = { 
                if ((Get-ADDomain).ComputersContainer -eq $($Using:Node.ADDefaultComputersOU)) {
                    Return $true
                    
                }else {
                    Return $false
                }
            }
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }

		 Script SetDefaultOUUser
        {
            PSDSCRunAsCredential = $DomainAdminCredential
            SetScript = { 
                redirusr $($Using:Node.ADDefaultUsersOU)
            }
            GetScript = {
                Return @{
                    'CurrentOU' = (Get-ADDomain).UsersContainer;
                }
            }
            TestScript = { 
                if ((Get-ADDomain).UsersContainer -eq $($Using:Node.ADDefaultUsersOU)) {
                    Return $true
                    
                }else {
                    Return $false
                }
            }
            DependsOn = '[xWaitForADDomain]DscForestWait'
        }


        [Int]$Count=0
        Foreach ($Scope in $Node.Scopes) {
            $Count++
            xDhcpServerScope "Scope$Count"
            {
                Ensure = 'Present'
                IPStartRange = $Scope.Start
                IPEndRange = $Scope.End
                Name = $Scope.Name
                SubnetMask = $Scope.SubnetMask
                State = 'Active'
                LeaseDuration = '00:08:00'
                AddressFamily = $Scope.AddressFamily
            }
        }
        [Int]$Count=0
        Foreach ($Reservation in $Node.Reservations) {
            $Count++
            xDhcpServerReservation "Reservation$Count"
            {
                Ensure = 'Present'
                ScopeID = $Reservation.ScopeId
                ClientMACAddress = $Reservation.ClientMACAddress
                IPAddress = $Reservation.IPAddress
                Name = $Reservation.Name
                AddressFamily = $Reservation.AddressFamily
            }
        }
        [Int]$Count=0
        Foreach ($ScopeOption in $Node.ScopeOptions) {
            $Count++
            xDhcpServerOption "ScopeOption$Count"
            {
                Ensure = 'Present'
                ScopeID = $ScopeOption.ScopeId
                DnsDomain = $Node.DomainName
                DnsServerIPAddress = $ScopeOption.DNServerIPAddress
                Router = $ScopeOption.Router
                AddressFamily = $ScopeOption.AddressFamily
            }
        }
    
		[Int]$Count=0
        Foreach ($iSCSIDisk in $Node.iScsiDisks) 
        {   
            $Count++
            ciSCSIVirtualDisk "iSCSIDisk$Count"
            {
                Ensure = 'Present'
                Path = $iSCSIDisk.path
                DiskType = $iSCSIDisk.DiskType
                SizeBytes = $iSCSIDisk.SizeBytes
                Description = $iSCSIDisk.Description
                DependsOn = "[WindowsFeature]ISCSITargetServerInstall" 
            } # End of ciSCSIVirtualDisk Resource
       }
		[Int]$Count=0
       Foreach ($iSCSITarget in $Node.iSCSITargets){    
                    $Count++
            ciSCSIServerTarget "iSCSITarget$Count"
            {
                Ensure = 'Present'
                TargetName = $iSCSITarget.TargetName
                InitiatorIds = $iSCSITarget.initiatorIDs
                Paths = $iSCSITarget.paths
                DependsOn = $iSCSITarget.DependsOn 
            } # End of ciSCSIServerTarget Resource
       }

    }
}
