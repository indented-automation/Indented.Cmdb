function GetCmdbItemObject {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Abstracts execution of the object resulting in execution of a CmdbItem.
    #
    #   Previously built objects are cached.
    # .PARAMETER CmdbItem
    #   A CmdbItem discovered by Get-CmdbItem.
    # .INPUTS
    #   System.Management.Automation.PSObject
    # .OUTPUTS
    #   System.Management.Automation.PSObject
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     08/07/2016 - Chris Dent - Created.

    param(
        $CmdbItem
    )

    [String]$name = $CmdbItem.Name
    if (-not $Script:cmdbItems.ContainsKey($name)) {
        $cmdbItemObject = . $CmdbItem.Path
        $Script:cmdbItems.Add($name, $cmdbItemObject)
    }
    if ($Script:cmdbItems.ContainsKey($name)) {
        $Script:cmdbItems[$name]
    }
}