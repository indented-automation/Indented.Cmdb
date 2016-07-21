function UpdateObjectStructure {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Updates the object structure before sending a set request to the data service.
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
        [PSObject[]]$Data,

        [String]$ItemPath
    )

    $baseObject = $psObject = New-Object PSObject
    foreach ($PropertyName in $ItemPath.Split('\')) {
        $immediateParent = $psObject
        Add-Member $PropertyName (New-Object PSObject) -InputObject $psObject
        $psObject = $psObject.$PropertyName
    }
    $immediateParent.$PropertyName = $Data

    return $baseObject
}