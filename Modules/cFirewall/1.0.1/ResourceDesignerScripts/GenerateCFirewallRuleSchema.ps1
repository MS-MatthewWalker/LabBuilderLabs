
#requires -Version 4.0 -Modules xDSCResourceDesigner

$ModuleName = 'cFirewall'
$ResourceName = 'cFirewallRule'

$DscResourceProperties =  @(
    (New-xDscResourceProperty -Attribute Key   -Name Name -Type String)
    (New-xDscResourceProperty -Attribute Write -Name Action -Type String -ValidateSet 'Allow', 'Block')
    (New-xDscResourceProperty -Attribute Write -Name Description -Type String)
    (New-xDscResourceProperty -Attribute Write -Name Direction -Type String -ValidateSet 'Inbound', 'Outbound')
    (New-xDscResourceProperty -Attribute Write -Name Enabled -Type Boolean)
    (New-xDscResourceProperty -Attribute Write -Name Ensure -Type String -ValidateSet 'Absent', 'Present')
    (New-xDscResourceProperty -Attribute Write -Name Group -Type String)
    (New-xDscResourceProperty -Attribute Write -Name LocalAddress -Type String[])
    (New-xDscResourceProperty -Attribute Write -Name LocalPort -Type String[])
    (New-xDscResourceProperty -Attribute Write -Name Profile -Type String[])
    (New-xDscResourceProperty -Attribute Write -Name Program -Type String)
    (New-xDscResourceProperty -Attribute Write -Name Protocol -Type String)
    (New-xDscResourceProperty -Attribute Write -Name RemoteAddress -Type String[])
    (New-xDscResourceProperty -Attribute Write -Name RemotePort -Type String[])
    (New-xDscResourceProperty -Attribute Write -Name Service -Type String)
)

New-xDscResource -Name $ResourceName -ModuleName $ModuleName -Property $DscResourceProperties -Verbose

