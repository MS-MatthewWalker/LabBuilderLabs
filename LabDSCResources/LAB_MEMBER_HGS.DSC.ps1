<#########################################################################################################################################
DSC Template Configuration File For use by LabBuilder
.Title
	MEMBER_HGS
.Desription
	Builds a Server and then installs HGS components.
	
.Parameters:          

#########################################################################################################################################>

Configuration LAB_MEMBER_HGS
{
	Import-DscResource -ModuleName 'PSDesiredStateConfiguration' 
	Import-DscResource -ModuleName xActiveDirectory
	Import-DscResource -ModuleName xComputerManagement

	Node $AllNodes.NodeName {
		# Assemble the Local Admin Credentials
		If ($Node.LocalAdminPassword) {
			[PSCredential]$LocalAdminCredential = New-Object System.Management.Automation.PSCredential ("Administrator", (ConvertTo-SecureString $Node.LocalAdminPassword -AsPlainText -Force))
		}
		If ($Node.DomainAdminPassword) {
			[PSCredential]$DomainAdminCredential = New-Object System.Management.Automation.PSCredential ("$($Node.DomainName)\Administrator", (ConvertTo-SecureString $Node.DomainAdminPassword -AsPlainText -Force))
		}
        
        WindowsFeature DNSInstall 
        { 
            Ensure = "Present" 
            Name = "DNS" 
		} 

		WindowsFeature HGSInstall 
        { 
            Ensure = "Present" 
            Name = "HostGaurdianServiceRole" 
        } 

		WindowsFeature RSATADPowerShell
        { 
            Ensure = "Present" 
            Name = "RSAT-AD-PowerShell" 
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

	}
}
