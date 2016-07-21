function SetRecord {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Modifies an existing record the data service.
    # .PARAMETER Record
    #   The existing record.
    # .PARAMETER NewRecord
    #   The new record fragment to add.
    # .PARAMETER OverwritePath
    #   Overwrite record data at the specified path.
    # .INPUTS
    #   System.Management.Automation.PSObject
    #   System.String
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     07/07/2016 - Chris Dent - Created.

    param(
        [PSObject]$Record,

        [PSObject]$NewRecord,

        [String]$OverwritePath
    )

    switch ($Script:settings.DatabaseMode) {
        { $_ -in 'Folder', 'Memory' } {
            if ($OverwritePath) {
                # Merge items from newRecord into Record.
                $source = $NewRecord
                $destination = $Record

                $OverwritePath.Split('\') | ForEach-Object {
                    $propertyName = $_

                    $immediateParent = $destination
                    $source = $source.$PropertyName

                    if (-not $destination.PSObject.Properties.Item($propertyName)) {
                        $destination | Add-Member $propertyName (New-Object PSObject)
                    }
                    $destination = $destination.$PropertyName
                }
                $immediateParent.$propertyName = $source
            }
            # Merge node properties
            $NewRecord.Node.PSObject.Properties | ForEach-Object {
                if (-not $Record.Node.PSObject.Properties.Item($_.Name)) {
                    Add-Member $_.Name $_.Value -InputObject $Record.Node
                } else {
                    $Record.Node.($_.Name) = $_.Value
                }
            }

            $updatedRecord = $Record | ConvertTo-Json -Depth $Script:settings.JsonDepth
        }
        'Folder' {
            $path = Join-Path $Script:settings.DatabaseURI "$($Record.Node.Name).json"
            $updatedRecord | Set-Content $path 
            break
        }
        'Memory' {
            $Script:data[$Record.Node.Name.ToLower()] = $updatedRecord
            break
        }
        'MongoDB' {
            # In theory I should simply be able to pass NewRecord to MongoDB as an update.
            break
        }
    }
}