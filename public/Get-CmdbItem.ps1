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

    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    [OutputType([System.Management.Automation.PSObject[]])]
    param(
        [Parameter(Position = 1, ParameterSetName = 'ByName')]
        [String]$Name = '*',

        [Parameter(ParameterSetName = 'ByItemPath')]
        [String]$ItemPath
    )

    $itemBasePath = Join-Path $myinvocation.MyCommand.Module.ModuleBase 'CmdbItems'

    $i = 0
    if ($pscmdlet.ParameterSetName -eq 'ByName') {
        Get-ChildItem $itemBasePath -Recurse -Filter "$Name.ps1" | ForEach-Object {
            $i++
            [PSCustomObject]@{
                Name     = $_.BaseName
                ItemPath = $_.FullName.Replace("$itemBasePath\", '').Replace('.ps1', '')
                Path     = $_.FullName
            }
        }
    } elseif ($pscmdlet.ParameterSetName -eq 'ByItemPath') {
        $itemPath = (Join-Path $itemBasePath $ItemPath) + '.ps1'
        if (Test-Path $itemPath) {
            $item = Get-Item $itemPath
            $i++
            [PSCustomObject]@{
                Name     = $item.BaseName
                ItemPath = $item.FullName.Replace("$itemBasePath\", '').Replace('.ps1', '')
                Path     = $item.FullName
            }
        }
    }
    if ($i -eq 0 -and ($Name.IndexOf('*') -eq -1 -or $pscmdlet.ParameterSetName -eq 'ByItemPath')) {
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            (New-Object ArgumentException 'The requested item does not exist'),
            'InvalidItem',
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            $Name
        )
        Write-Error -ErrorRecord $errorRecord
    }
}