<#########################################################################################################################################
DSC Template Configuration File For use by LabBuilder
.Title
	MEMBER_FAILOVERCLUSTER
.Desription
	Builds a Network failover clustering node.
.Parameters:    
		  DomainName = "LABBUILDER.COM"
		  DomainAdminPassword = "P@ssword!1"
		  PSDscAllowDomainUser = $True
#########################################################################################################################################>
Configuration LAB_MEMBER_FAILOVERCLUSTER
{
	Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
	Import-DscResource -ModuleName xActiveDirectory
	Import-DscResource -ModuleName xComputerManagement
	Import-DscResource -ModuleName xPSDesiredStateConfiguration
	Import-DscResource -ModuleName ciscsi 
	Import-DscResource -ModuleName xFailoverCluster 
	Import-DscResource -ModuleName xStorage





	Node $AllNodes.NodeName {
		# Assemble the Local Admin Credentials
		If ($Node.LocalAdminPassword) {
			[PSCredential]$LocalAdminCredential = New-Object System.Management.Automation.PSCredential ("Administrator", (ConvertTo-SecureString $Node.LocalAdminPassword -AsPlainText -Force))
		}
		If ($Node.DomainAdminPassword) {
			[PSCredential]$DomainAdminCredential = New-Object System.Management.Automation.PSCredential ("$($Node.DomainName)\Administrator", (ConvertTo-SecureString $Node.DomainAdminPassword -AsPlainText -Force))
		}
        

		# Install the RSAT PowerShell Module which is required by the xWaitForResource
		WindowsFeature RSATADPowerShell
		{ 
			Ensure = "Present" 
			Name = "RSAT-AD-PowerShell" 
		} 

		WindowsFeature FailoverClusteringInstall
		{ 
			Ensure = "Present" 
			Name = "Failover-Clustering" 
		} 

        WindowsFeature FailoverClusteringPSInstall
        {
            Ensure = "Present" 
            Name = "RSAT-Clustering-PowerShell" 
        }

        WindowsFeature FailoverClusteringMgmt
        {
            Ensure = "Present" 
            Name = "RSAT-Clustering-Mgmt" 
        }


        WindowsFeature FileServerInstall 
        {
            Ensure = "Present" 
            Name = "FS-FileServer" 
            DependsOn = "[WindowsFeature]FailoverClusteringPSInstall" 
        }


		# Wait for the Domain to be available so we can join it.
		xWaitForADDomain DscDomainWait
		{
			DomainName = $Node.DomainName
			DomainUserCredential = $DomainAdminCredential 
			RetryCount = 100 
			RetryIntervalSec = 10 
			DependsOn = "[WindowsFeature]RSATADPowerShell" 
		}

		# Join this Server to the Domain.
		xComputer JoinDomain 
		{ 
			Name          = $Node.NodeName
			DomainName    = $Node.DomainName
			Credential    = $DomainAdminCredential 
			DependsOn = "[xWaitForADDomain]DscDomainWait" 
		}

		# Create Cluster for SMB Shares
		if ($Node.ClusterName) 
		{
		xCluster ensureCreated
			{
				Name = $Node.ClusterName
				StaticIPAddress = $Node.ClusterIPAddress
				DomainAdministratorCredential = $DomainAdminCredential
				DependsOn = "[xComputer]JoinDomain"
			} 

    	}
	    
		if ($Node.JoinClusterName) 
		{
			xWaitForCluster WaitForCluster
			{
				Name = $Node.JoinClusterName
				RetryIntervalSec = 10
				RetryCount = 60

				DependsOn = "[xComputer]JoinDomain"
			}

			xCluster JoinCluster
			{
				Name = $Node.JoinClusterName
				StaticIPAddress = $Node.JoinClusterIPAddress
				DomainAdministratorCredential = $DomainAdminCredential

				DependsOn = "[xWaitForCluster]waitForCluster"
			}  

		}

		if ($Node.SOFSName){

		 Script SOFSSetup
        { 
				PSDSCRunAsCredential = $DomainAdminCredential
                SetScript = {

				Write-Verbose -Message ("Add-ClusterScaleOutFileServerRole -Cluster $($using:Node.ClusterName) -Name $($using:Node.SOFSName) will be run")
                Add-ClusterScaleOutFileServerRole -Cluster $($using:Node.ClusterName) -Name $($using:Node.SOFSName)
			
				}
            GetScript = {

                Return @{
                    'State' = (@(Get-ClusterGroup | Where-Object { ($_.Name -eq $($using:Node.SOFSName))}));

                }
			}
            TestScript =  {

				$State = (Get-ClusterGroup | Where-Object {$_.Name -eq $($using:Node.SOFSName)}).State
				if ($State -eq 'Online')
				{
					Return $True
				}
				else
				{
					Return $False
				}
           }    
            DependsOn = '[xComputer]JoinDomain'
        }
		}

		if ($Node.Disks)
        {

            [int]$Count = 0
            foreach ($Disk in $Node.Disks)
            {
                xWaitForDisk $Disk.Name
                {
                    DiskId = $Disk.number
                    RetryIntervalSec = "5"
                    RetryCount = "10"
                }
                
                xDisk $Disk.Name
                {
                    DiskId =$Disk.number
                    DriveLetter = $Disk.DriveLetter
                    FSLabel = $Disk.FSLabel

                }
            }
        } # End Disk Format
 
        if ($Node.ServerTargetName)
        {
            # Ensure the iSCSI Initiator service is running
            Service iSCSIService 
            { 
                Name = 'MSiSCSI'
                StartupType = 'Automatic'
                State = 'Running'
            }

            WaitForAny WaitForiSCSIServerTarget
            {
                ResourceName = "[ciSCSIServerTarget]iSCSITarget2"
                NodeName = $Node.ServerName
                RetryIntervalSec = 30
                RetryCount = 30
                DependsOn = "[Service]iSCSIService"
            }

            # Connect the Initiator
            ciSCSIInitiator iSCSIInitiator
            {
                Ensure = 'Present'
                NodeAddress = "iqn.1991-05.com.microsoft:$($Node.ServerTargetName)"
                TargetPortalAddress = $Node.TargetPortalAddress
                InitiatorPortalAddress = $Node.InitiatorPortalAddress
                IsPersistent = $true 
                DependsOn = "[Service]iSCSIService" 
            } # End of ciSCSITarget Resource

            # Enable iSCSI FireWall rules so that the Initiator can be added to iSNS
            xFirewall iSCSIFirewallIn
            {
                Name = "MsiScsi-In-TCP"
                Ensure = 'Present'
                Enabled = 'True'
            }
            xFirewall iSCSIFirewallOut
            {
                Name = "MsiScsi-Out-TCP"
                Ensure = 'Present'
                Enabled = 'True'
            }

        } # End iSCSI setup

		 			
	}
}
