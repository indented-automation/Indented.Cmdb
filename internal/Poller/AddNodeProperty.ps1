function AddNodeProperty {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Merges properties declared in the CopyToNode value of a CmdbItem back into the Node object.
    # .PARAMETER PropertyName
    #   A list of property names from Data to merge.
    # .PARAMETER Node
    #   The node to merge items into.
    # .PARAMETER Data
    #   The data containing the properties.
    # .INPUTS
    #   System.Management.Automation.PSObject
    #   System.String
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #    08/07/2016 - Chris Dent - Created.

    param(
        [AllowNull()]
        [String[]]$PropertyName,

        [PSObject]$Node,

        [PSObject[]]$Data
    )

    if ($null -ne $PropertyName -and $PropertyName.Length -gt 0) {
        $PropertyName | ForEach-Object {
            Add-Member $_ $Data.$_ -InputObject $Node -Force
        }
    }
}