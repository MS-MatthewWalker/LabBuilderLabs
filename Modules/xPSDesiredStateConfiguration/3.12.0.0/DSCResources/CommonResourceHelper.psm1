﻿<#
    .SYNOPSIS
    Tests if the current machine is a Nano server.
#>
function Test-IsNanoServer
{
    [OutputType([Boolean])]
    [CmdletBinding()]
    param ()

    return $PSVersionTable.PSEdition -ieq 'Core'
}

<#
    .SYNOPSIS
        Creates and throws an invalid argument exception

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ArgumentName
        The name of the invalid argument that is causing this error to be thrown
#>
function New-InvalidArgumentException
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ArgumentName
    )

    $argumentException = New-Object -TypeName 'ArgumentException' -ArgumentList @( $Message, $ArgumentName )
    $errorRecord = New-Object -TypeName 'System.Management.Automation.ErrorRecord' -ArgumentList @( $argumentException, $ArgumentName, 'InvalidArgument', $null)

    throw $errorRecord
}

<#
    .SYNOPSIS
        Creates and throws an invalid operation exception

    .PARAMETER Message
        The message explaining why this error is being thrown

    .PARAMETER ErrorRecord
        The error record containing the exception that is causing this terminating error
#>
function New-InvalidOperationException
{
    [CmdletBinding()]
    param
    (
        [ValidateNotNullOrEmpty()]
        [String]
        $Message,

        [ValidateNotNull()]
        [System.Management.Automation.ErrorRecord]
        $ErrorRecord
    )

    if ($null -eq $Message)
    {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException'
    }
    elseif ($null -eq $ErrorRecord)
    {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException' -ArgumentList @( $Message )
    }
    else
    {
        $invalidOperationException = New-Object -TypeName 'InvalidOperationException' -ArgumentList @( $Message, $ErrorRecord.Exception)
    }

    $errorRecordToThrow = New-Object -TypeName 'System.Management.Automation.ErrorRecord' -ArgumentList @( $invalidOperationException.ToString(), 'MachineStateIncorrect', 'InvalidOperation' ,$null)
    throw $errorRecordToThrow
}

Export-ModuleMember -Function `
    Test-IsNanoServer, `
    Throw-InvalidArgumentException, `
    Throw-TerminatingError
