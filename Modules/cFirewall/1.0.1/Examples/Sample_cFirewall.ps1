
configuration Sample_cFirewall
{
    Import-DscResource -ModuleName cFirewall

    cFirewallRule FirewallRule1
    {
        Name = 'Allow Custom Rule'
        Action = 'Allow'
        Description = 'Created by the cFirewallRule DSC resource.'
        Direction = 'Inbound'
        Enabled = $true
        Ensure = 'Present'
        Group = 'DSC'
        LocalPort = '6465', '6500-6520'
        RemoteAddress = '192.168.0.10-192.168.0.20', '192.168.1.0/24', '192.168.2.10'
        Profile = 'Domain', 'Private'
        Protocol = 'TCP'
    }

    cFirewallRule FirewallRule2
    {
        Name = 'Allow Inbound HTTP Traffic'
        Action = 'Allow'
        Description = 'Created by the cFirewallRule DSC resource.'
        Direction = 'Inbound'
        Enabled = $true
        Ensure = 'Present'
        Group = 'DSC'
        LocalPort = '80'
        Profile = 'All'
        Protocol = 'TCP'
    }

    cFirewallRule FirewallRule3
    {
        Name = 'Block Outbound HTTP Traffic'
        Action = 'Block'
        Description = 'Created by the cFirewallRule DSC resource.'
        Direction = 'Outbound'
        Enabled = $true
        Ensure = 'Present'
        Group = 'DSC'
        LocalPort = '80'
        Profile = 'All'
        Protocol = 'TCP'
    }

}

Sample_cFirewall -OutputPath "$Env:SystemDrive\Sample_cFirewall"

Start-DscConfiguration -Path "$Env:SystemDrive\Sample_cFirewall" -Force -Verbose -Wait

Get-DscConfiguration

