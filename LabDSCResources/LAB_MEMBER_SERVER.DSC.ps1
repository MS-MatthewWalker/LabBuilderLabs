<#########################################################################################################################################
DSC Template Configuration File For use by LabBuilder
.Title
	MEMBER_FILESERVER
.Desription
	Builds a Server that is joined to a domain and then made into a File Server.
.Parameters:          
	DomainName = "LABBUILDER.COM"
	DomainAdminPassword = "P@ssword!1"
#########################################################################################################################################>

Configuration LAB_MEMBER_SERVER
{
	Import-DscResource -ModuleName 'PSDesiredStateConfiguration' 
	Import-DscResource -ModuleName xActiveDirectory 
	Import-DscResource -ModuleName xComputerManagement 
	Import-DscResource -ModuleName xStorage  
	Import-DscResource -ModuleName xNetworking 
	Import-DscResource -ModuleName ciscsi 
    

	Node $AllNodes.NodeName {
		# Assemble the Local Admin Credentials
		If ($Node.LocalAdminPassword) {
			[PSCredential]$LocalAdminCredential = New-Object System.Management.Automation.PSCredential ("Administrator", (ConvertTo-SecureString $Node.LocalAdminPassword -AsPlainText -Force))
		}
		If ($Node.DomainAdminPassword) {
			[PSCredential]$DomainAdminCredential = New-Object System.Management.Automation.PSCredential ("$($Node.DomainName)\Administrator", (ConvertTo-SecureString $Node.DomainAdminPassword -AsPlainText -Force))
		}


		WindowsFeature RSATADPowerShell
		{ 
			Ensure = "Present" 
			Name = "RSAT-AD-PowerShell" 
			
		} 

        WaitForAll DC
        {
        ResourceName      = '[xADDomain]PrimaryDC'
        NodeName          = 'DC'
        RetryIntervalSec  = 15
        RetryCount        = 60
        }


		xWaitForADDomain DscDomainWait
		{
			DomainName = $Node.DomainName
			DomainUserCredential = $DomainAdminCredential 
			RetryCount = 100 
			RetryIntervalSec = 10 
			DependsOn = "[WindowsFeature]RSATADPowerShell" 
		}

		xComputer JoinDomain 
		{ 
			Name          = $Node.NodeName
			DomainName    = $Node.DomainName
			Credential    = $DomainAdminCredential 
			DependsOn = '[WaitForAll]DC'
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
        }
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
                ResourceName = "[ciSCSIServerTarget]iSCSITarget1"
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
        }
				
	}
}
