﻿# Import the Networking Resource Helper Module
Import-Module -Name (Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) `
                               -ChildPath (Join-Path -Path 'NetworkingDsc.ResourceHelper' `
                                                     -ChildPath 'NetworkingDsc.ResourceHelper.psm1'))

# Import Localization Strings
$script:localizedData = Get-LocalizedData `
    -ResourceName 'NetworkingDsc.Common' `
    -ResourcePath $PSScriptRoot

<#
    .SYNOPSIS
    Converts any IP Addresses containing CIDR notation filters in an array to use Subnet Mask
    notation.

    .PARAMETER Address
    The array of addresses to that need to be converted.
#>
function Convert-CIDRToSubhetMask
{
    [CmdletBinding()]
    [OutputType([ Microsoft.Management.Infrastructure.CimInstance])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $Address
    )

    $Results = @()
    foreach ($Entry in $Address)
    {
        if (-not $Entry.Contains(':') -and -not $Entry.Contains('-'))
        {
            $EntrySplit = $Entry -split '/'
            if (-not [String]::IsNullOrEmpty($EntrySplit[1]))
            {
                # There was a / so this contains a Subnet Mask or CIDR
                $Prefix = $EntrySplit[0]
                $Postfix = $EntrySplit[1]
                if ($Postfix -match '^[0-9]*$')
                {
                    # The postfix contains CIDR notation so convert this to Subnet Mask
                    $Cidr = [Int] $Postfix
                    $SubnetMaskInt64 = ([convert]::ToInt64(('1' * $Cidr + '0' * (32 - $Cidr)), 2))
                    $SubnetMask = @(
                            ([math]::Truncate($SubnetMaskInt64 / 16777216))
                            ([math]::Truncate(($SubnetMaskInt64 % 16777216) / 65536))
                            ([math]::Truncate(($SubnetMaskInt64 % 65536)/256))
                            ([math]::Truncate($SubnetMaskInt64 % 256))
                        )
                }
                else
                {
                    $SubnetMask = $Postfix -split '\.'
                }
                # Apply the Subnet Mast to the IP Address so that we end up with a correctly
                # masked IP Address that will match what the Firewall rule returns.
                $MaskedIp = $Prefix -split '\.'
                for ([int] $Octet = 0; $Octet -lt 4; $Octet++)
                {
                    $MaskedIp[$Octet] = $MaskedIp[$Octet] -band $SubnetMask[$Octet]
                }
                $Entry = '{0}/{1}' -f ($MaskedIp -join '.'),($SubnetMask -join '.')
            }
        }
        $Results += $Entry
    }
    return $Results
} # Convert-CIDRToSubhetMask

<#
    .SYNOPSIS
    This function will find a network adapter based on the provided
    search parameters.

    .PARAMETER Name
    This is the name of network adapter to find.

    .PARAMETER PhysicalMediaType
    This is the media type of the network adapter to find.

    .PARAMETER Status
    This is the status of the network adapter to find.

    .PARAMETER MacAddress
    This is the MAC address of the network adapter to find.

    .PARAMETER InterfaceDescription
    This is the interface description of the network adapter to find.

    .PARAMETER InterfaceIndex
    This is the interface index of the network adapter to find.

    .PARAMETER InterfaceGuid
    This is the interface GUID of the network adapter to find.

    .PARAMETER DriverDescription
    This is the driver description of the network adapter.

    .PARAMETER InterfaceNumber
    This is the interface number of the network adapter if more than one
    are returned by the parameters.

    .PARAMETER IgnoreMultipleMatchingAdapters
    This switch will suppress an error occurring if more than one matching
    adapter matches the parameters passed.
#>
function Find-NetworkAdapter
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter()]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $PhysicalMediaType,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Up','Disconnected','Disabled')]
        [System.String]
        $Status = 'Up',

        [Parameter()]
        [System.String]
        $MacAddress,

        [Parameter()]
        [System.String]
        $InterfaceDescription,

        [Parameter()]
        [System.UInt32]
        $InterfaceIndex,

        [Parameter()]
        [System.String]
        $InterfaceGuid,

        [Parameter()]
        [System.String]
        $DriverDescription,

        [Parameter()]
        [System.UInt32]
        $InterfaceNumber = 1,

        [Parameter()]
        [System.Boolean]
        $IgnoreMultipleMatchingAdapters = $false
    )

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
        $($LocalizedData.FindingNetAdapterMessage)
        ) -join '')

    $adapterFilters = @()
    if($PSBoundParameters.ContainsKey('Name'))
    {
        $adapterFilters += @('($_.Name -eq $Name)')
    } # if

    if($PSBoundParameters.ContainsKey('PhysicalMediaType'))
    {
        $adapterFilters += @('($_.PhysicalMediaType -eq $PhysicalMediaType)')
    } # if

    if($PSBoundParameters.ContainsKey('Status')) {
        $adapterFilters += @('($_.Status -eq $Status)')
    } # if

    if($PSBoundParameters.ContainsKey('MacAddress'))
    {
        $adapterFilters += @('($_.MacAddress -eq $MacAddress)')
    } # if

    if($PSBoundParameters.ContainsKey('InterfaceDescription'))
    {
        $adapterFilters += @('($_.InterfaceDescription -eq $InterfaceDescription)')
    } # if

    if($PSBoundParameters.ContainsKey('InterfaceIndex'))
    {
        $adapterFilters += @('($_.InterfaceIndex -eq $InterfaceIndex)')
    } # if

    if($PSBoundParameters.ContainsKey('InterfaceGuid'))
    {
        $adapterFilters += @('($_.InterfaceGuid -eq $InterfaceGuid)')
    } # if

    if($PSBoundParameters.ContainsKey('DriverDescription'))
    {
        $adapterFilters += @('($_.DriverDescription -eq $DriverDescription)')
    } # if

    if ($adapterFilters.Count -eq 0)
    {
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($LocalizedData.AllNetAdaptersFoundMessage)
            ) -join '')

        $matchingAdapters = @(Get-NetAdapter)
    }
    else
    {
        # Join all the filters together
        $adapterFilterScript = '(' + ($adapterFilters -join ' -and ') + ')'
        $matchingAdapters = @(Get-NetAdapter |
            Where-Object -FilterScript ([ScriptBlock]::Create($adapterFilterScript)))
    }

    # Were any adapters found matching the criteria?
    if ($matchingAdapters.Count -eq 0)
    {
        New-InvalidOperationException `
            -Message ($LocalizedData.NetAdapterNotFoundError)

        # Return a null so that ErrorAction SilentlyContinue works correctly
        return $null
    }
    else
    {
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($LocalizedData.NetAdapterFoundMessage -f $matchingAdapters.Count)
            ) -join '')

        if ($matchingAdapters.Count -gt 1)
        {
            if ($IgnoreMultipleMatchingAdapters)
            {
                # Was the number of matching adapters found matching the adapter number?
                if (($InterfaceNumber -gt 1) -and ($InterfaceNumber -gt $matchingAdapters.Count))
                {
                    New-InvalidOperationException `
                        -Message ($LocalizedData.InvalidNetAdapterNumberError `
                            -f $matchingAdapters.Count,$InterfaceNumber)

                    # Return a null so that ErrorAction SilentlyContinue works correctly
                    return $null
                } # if
            }
            else
            {
                New-InvalidOperationException `
                    -Message ($LocalizedData.MultipleMatchingNetAdapterFound `
                        -f $matchingAdapters.Count)

                # Return a null so that ErrorAction SilentlyContinue works correctly
                return $null
            } # if
        } # if
    } # if

    # Identify the exact adapter from the adapters that match
    $exactAdapter = $matchingAdapters[$InterfaceNumber - 1]

    $returnValue = [PSCustomObject] @{
        Name                 = $exactAdapter.Name
        PhysicalMediaType    = $exactAdapter.PhysicalMediaType
        Status               = $exactAdapter.Status
        MacAddress           = $exactAdapter.MacAddress
        InterfaceDescription = $exactAdapter.InterfaceDescription
        InterfaceIndex       = $exactAdapter.InterfaceIndex
        InterfaceGuid        = $exactAdapter.InterfaceGuid
        MatchingAdapterCount = $matchingAdapters.Count
    }

    return $returnValue
} # Find-NetworkAdapter

<#
    .SYNOPSIS
    Returns the DNS Client Server static address that are assigned to a network
    adapter. This is required because Get-DnsClientServerAddress always returns
    the currently assigned server addresses whether regardless if they were
    assigned as static or by DHCP.

    The only way that could be found to do this is to query the registry.

    .PARAMETER InterfaceAlias
    Alias of the network interface to get the static DNS Server addresses from.

    .PARAMETER AddressFamily
    IP address family.
#>
function Get-DnsClientServerStaticAddress
{
    [CmdletBinding()]
    [OutputType([String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $InterfaceAlias,

        [Parameter(Mandatory = $true)]
        [ValidateSet('IPv4', 'IPv6')]
        [String]
        $AddressFamily
    )

    Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
        $($LocalizedData.GettingDNSServerStaticAddressMessage) -f $AddressFamily,$InterfaceAlias
        ) -join '')

    # Look up the interface Guid
    $adapter = Get-NetAdapter `
        -InterfaceAlias $InterfaceAlias `
        -ErrorAction SilentlyContinue

    if (-not $adapter)
    {
        New-InvalidOperationException `
            -Message ($LocalizedData.InterfaceAliasNotFoundError `
                -f $InterfaceAlias)

        # Return null to support ErrorAction Silently Continue
        return $null
    } # if

    $interfaceGuid = $adapter.InterfaceGuid.ToLower()

    if ($AddressFamily -eq 'IPv4')
    {
        $interfaceRegKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$interfaceGuid\"
    }
    else
    {
        $interfaceRegKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\Interfaces\$interfaceGuid\"
    } # if

    $nameServerAddressString = Get-ItemPropertyValue `
        -Path $interfaceRegKeyPath `
        -Name NameServer `
        -ErrorAction SilentlyContinue

    # Are any statically assigned addresses for this adapter?
    if ([String]::IsNullOrWhiteSpace($nameServerAddressString))
    {
        # Static DNS Server addresses not found so return empty array
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($LocalizedData.DNSServerStaticAddressNotSetMessage) -f $AddressFamily,$InterfaceAlias
            ) -join '')

        return $null
    }
    else
    {
        # Static DNS Server addresses found so split them into an array using comma
        Write-Verbose -Message ( @("$($MyInvocation.MyCommand): "
            $($LocalizedData.DNSServerStaticAddressFoundMessage) -f $AddressFamily,$InterfaceAlias,$nameServerAddressString
            ) -join '')

        return @($nameServerAddressString -split ',')
    } # if
} # Get-DnsClientServerStaticAddress

<#
.SYNOPSIS
    Gets the IP Address prefix from a provided IP Address in CIDR notation.

.PARAMETER IPAddress
    IP Address to get prefix for, can be in CIDR notation.

.PARAMETER AddressFamily
    Address family for provided IP Address, defaults to IPv4.

#>
function Get-IPAddressPrefix
{
    [cmdletbinding()]
    param
    (
        [parameter(Mandatory=$True, ValueFromPipeline)]
        [string[]]$IPAddress,

        [parameter()]
        [ValidateSet('IPv4','IPv6')]
        [string]$AddressFamily = 'IPv4'
    )

    process
    {
        foreach ($singleIP in $IPAddress)
        {
            $prefixLength = ($singleIP -split '/')[1]

            If (-not ($prefixLength) -and $AddressFamily -eq 'IPv4')
            {
                if ($singleIP.split('.')[0] -in (0..127))
                {
                    $prefixLength = 8
                }
                elseif ($singleIP.split('.')[0] -in (128..191))
                {
                    $prefixLength = 16
                }
                elseif ($singleIP.split('.')[0] -in (192..223))
                {
                    $prefixLength = 24
                }
            }
            elseif (-not ($prefixLength) -and $AddressFamily -eq 'IPv6')
            {
                $prefixLength = 64
            }

            [PSCustomObject]@{
                IPAddress = $singleIP.split('/')[0]
                prefixLength = $prefixLength
            }
        }
    }
}

Export-ModuleMember -Function `
    Convert-CIDRToSubhetMask, `
    Find-NetworkAdapter,
    Get-DnsClientServerStaticAddress,
    Get-IPAddressPrefix
