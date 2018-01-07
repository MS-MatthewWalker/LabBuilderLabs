<###################################################################################################
DSC Template Configuration File For use by LabBuilder
.Title
    MEMBER_FAILOVERCLUSTER_FS
.Desription
    Builds a Network failover clustering node for use as a File Server.
    It also optionally starts the iSCSI Initiator and connects to any specified iSCSI Targets.
.Parameters:
    DomainName = "LABBUILDER.COM"
    DomainAdminPassword = "P@ssword!1"
    DCName = 'SA-DC1'
    PSDscAllowDomainUser = $True
    ServerName = 'SA-FS1'
    ServerTargetName = 'sa-fs1-sa-foc-target-target'
    TargetPortalAddress = '192.168.129.24'
    InitiatorPortalAddress = '192.168.129.28'
###################################################################################################>

Configuration LAB_MEMBER_FAILOVERCLUSTER_FS
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'
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

        Service iSCSIService 
        { 
            Name = 'MSiSCSI'
            StartupType = 'Automatic'
            State = 'Running'  
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
            DependsOn = "[WindowsFeature]FailoverClusteringInstall" 
        }

        WindowsFeature FileServerInstall 
        {
            Ensure = "Present" 
            Name = "FS-FileServer" 
            DependsOn = "[WindowsFeature]FailoverClusteringPSInstall" 
        }

        WindowsFeature DataDedupInstall 
        { 
            Ensure = "Present" 
            Name = "FS-Data-Deduplication" 
            DependsOn = "[WindowsFeature]FileServerInstall" 
        }

        WindowsFeature BranchCacheInstall 
        { 
            Ensure = "Present" 
            Name = "FS-BranchCache" 
            DependsOn = "[WindowsFeature]DataDedupInstall" 
        }

        WindowsFeature DFSNameSpaceInstall 
        { 
            Ensure = "Present" 
            Name = "FS-DFS-Namespace" 
            DependsOn = "[WindowsFeature]BranchCacheInstall" 
        }

        WindowsFeature DFSReplicationInstall 
        { 
            Ensure = "Present" 
            Name = "FS-DFS-Replication" 
            DependsOn = "[WindowsFeature]DFSNameSpaceInstall" 
        }

        WindowsFeature FSResourceManagerInstall 
        { 
            Ensure = "Present" 
            Name = "FS-Resource-Manager" 
            DependsOn = "[WindowsFeature]DFSReplicationInstall" 
        }

        # Wait for the Domain to be available so we can join it.
        WaitForAll DC
        {
        ResourceName      = '[xADDomain]PrimaryDC'
        NodeName          = $Node.DCname
        RetryIntervalSec  = 15
        RetryCount        = 60
        }

        # Add in any disks defined    
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


        # Join this Server to the Domain so that it can be an Enterprise CA.
        xComputer JoinDomain 
        { 
            Name          = $Node.NodeName
            DomainName    = $Node.DomainName
            Credential    = $DomainAdminCredential 
            DependsOn = "[WaitForAll]DC" 
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

        # Enable FSRM FireWall rules so we can remote manage FSRM
        xFirewall FSRMFirewall1
        {
            Name = "FSRM-WMI-ASYNC-In-TCP"
            Ensure = 'Present'
            Enabled = 'True'
        }

        xFirewall FSRMFirewall2
        {
            Name = "FSRM-WMI-WINMGMT-In-TCP"
            Ensure = 'Present'
            Enabled = 'True' 
        }

        xFirewall FSRMFirewall3
        {
            Name = "FSRM-RemoteRegistry-In (RPC)"
            Ensure = 'Present'
            Enabled = 'True' 
        }
        
        xFirewall FSRMFirewall4
        {
            Name = "FSRM-Task-Scheduler-In (RPC)"
            Ensure = 'Present'
            Enabled = 'True' 
        }

        xFirewall FSRMFirewall5
        {
            Name = "FSRM-SrmReports-In (RPC)"
            Ensure = 'Present'
            Enabled = 'True' 
        }

        xFirewall FSRMFirewall6
        {
            Name = "FSRM-RpcSs-In (RPC-EPMAP)"
            Ensure = 'Present'
            Enabled = 'True' 
        }
        
        xFirewall FSRMFirewall7
        {
            Name = "FSRM-System-In (TCP-445)"
            Ensure = 'Present'
            Enabled = 'True' 
        }
        
        xFirewall FSRMFirewall8
        {
            Name = "FSRM-SrmSvc-In (RPC)"
            Ensure = 'Present'
            Enabled = 'True'
        }
    }
}
