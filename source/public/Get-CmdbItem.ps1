function Get-CmdbItem {
    # .SYNOPSIS
    #   Get a CMDB item.
    # .DESCRIPTION
    #   CMDB items are used to harvest data from remote systems. Each CmdbItem is implemented using the CmdbItem keyword.
    # .PARAMETER Name
    #   Get a specific item, by default all items are returned. Wildcards are supported.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   System.Management.Automation.PSObject
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     08/07/2016 - Chris Dent - Added error message return when Name does not contain a wildcard and no items exist.
    #     01/07/2016 - Chris Dent - Created.

    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSObject[]])]
    param(
        [Parameter(Position = 1)]
        [String]$Name = '*',

        [String]$Path = $Script:settings.CmdbItemPath
    )

    $i = 0
    # This is dangerous, unconstrained path based invocation
    Get-ChildItem $Path -Filter "$Name.ps1" | ForEach-Object {
        $i++
        [PSCustomObject]@{
            Name     = $_.BaseName
            Path     = $_.FullName
        }
    }
    if ($i -eq 0 -and $Name.IndexOf('*') -eq -1) {
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            (New-Object ArgumentException 'The requested item does not exist'),
            'InvalidItem',
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            $Name
        )
        Write-Error -ErrorRecord $errorRecord
    }
}