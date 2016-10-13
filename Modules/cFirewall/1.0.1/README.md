# cFirewall

## Description

The **cFirewall** module contains the **cFirewallRule** DSC resource that provides a mechanism to manage firewall rules.

This module uses the following **Windows Firewall with Advanced Security API** interfaces:
* **[INetFwPolicy2](https://msdn.microsoft.com/en-us/library/windows/desktop/aa365309%28v=vs.85%29.aspx)**: Provides access to the firewall policy.
* **[INetFwRules](https://msdn.microsoft.com/en-us/library/windows/desktop/aa365345%28v=vs.85%29.aspx)**: Provides access to a collection of firewall rules in the firewall policy.
* **[INetFwRule](https://msdn.microsoft.com/en-us/library/windows/desktop/aa365344%28v=vs.85%29.aspx)**: Provides access to the properties of a firewall rule.

*Supports Windows Server 2008 R2 and later.*

You can also download this module from the [PowerShell Gallery](https://www.powershellgallery.com/packages/cFirewall/).

## Resources

### cFirewallRule

#### Description

The **cFirewallRule** resource does not modify identically named rules that already exist in the firewall policy. In case there are no fully matching rules, a new rule with the specified properties is created.

#### Properties

* **Name**: Indicates the name of the rule.
* **Action**: Indicates the action to take on traffic that matches this rule. The acceptable values for this property are: `Allow` or `Block`. The default value is `Allow`.
* **Description**: Indicates the description of this rule.
* **Direction**: Indicates the direction of traffic for which this rule applies. The acceptable values for this property are: `Inbound` or `Outbound`. The default value is `Inbound`.
* **Enabled**: Indicates whether the rule is enabled or disabled. Set this property to `$true` to ensure the rule is enabled.
* **Ensure**: Indicates whether the rule exists. Set this property to `Absent` to ensure all the matching rules are removed. The default value is `Present`.
* **Group**: Indicates the group to which this rule belongs.
* **LocalAddress**: Indicates the list of local addresses for this rule.
* **LocalPort**: Indicates the list of local ports for this rule.
* **Profiles**: Indicates the list of profiles to which the rule applies. The acceptable values for this parameter are: `Domain`, `Private`, `Public` or `All`. The default value is `All`.
* **Program**: Indicates the program to which this rule applies. Please note that environment variables are automatically expanded.
* **Protocol**: Indicates the protocol type for this rule. The list of acceptable values includes, but not limited to: `Any`, `ICMP`, `TCP`, `UDP` etc. The default value is `TCP`.
* **RemoteAddress**: Indicates the list of remote addresses for this rule.
* **RemotePort**: Indicates the list of remote ports for this rule.
* **Service**: Indicates the service to which this rule applies.

## Versions

### 1.0.1 (October 15, 2015)

* Minor update.

### 1.0.0 (October 14, 2015)

* Initial release with the following resources:
  - **cFirewallRule**.

## Examples

This configuration will ensure that multiple custom firewall rules exist.

```powershell

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


```

