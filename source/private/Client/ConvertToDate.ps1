function ConvertToDate {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Removes the extra members added to DateTime which make a bit of a mess of deserialization.
    #
    #   Ideally this should happen when objects are inserted into the database, this attempts to ensure
    #   it happens as data is extracted.
    # .INPUTS
    #   System.Int32
    #   System.Management.Automation.PSObject
    # .OUTPUTS
    #   System.Management.Automation.PSObject
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     22/08/2016 - Chris Dent - Created.

    param(
        [Parameter(ValueFromPipeline = $true)]
        [PSObject]$InputObject,

        [Int]$Depth = 1,

        [Int]$MaxDepth = 5
    )

    process {
        foreach ($property in $InputObject.PSObject.Properties) {
            if ($property.TypeNameOfValue -eq 'System.String' -and $property.Value.value -like '/Date(*)/') {
                $milliseconds = $property.Value.value.Substring(
                    $property.Value.value.IndexOf('(') + 1,
                    $property.Value.value.IndexOf(')') - $property.Value.value.IndexOf('(') - 1
                )
                $property.Value = (Get-Date '01/01/1970').AddMilliseconds($milliseconds)
            }

            if ($property.TypeNameOfValue -eq 'System.Management.Automation.PSCustomObject') {
                if ($property.Value.PSObject.Properties.Item('value') -and $property.Value.value -is [DateTime]) {
                    $property.Value = $property.Value.value
                } elseif ($property.Value.PSObject.Properties.Item('value') -and $property.Value.value -like '/Date(*)/') {
                    $milliseconds = $property.Value.value.Substring(
                        $property.Value.value.IndexOf('(') + 1,
                        $property.Value.value.IndexOf(')') - $property.Value.value.IndexOf('(') - 1
                    )
                    $property.Value = (Get-Date '01/01/1970').AddMilliseconds($milliseconds)
                } else {
                    if ($Depth -lt $MaxDepth) {
                        $property.Value = ConvertToDate $property.Value -Depth ($Depth + 1)
                    }
                } 
            }
        }

        $InputObject
    }
}