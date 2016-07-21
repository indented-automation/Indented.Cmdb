function AddRecord {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Add a new record to the data service.
    # .PARAMETER Record
    #   The record to add.
    # .INPUTS
    #   System.Management.Automation.PSObject
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     07/07/2016 - Chris Dent - Created.

    param(
        [PSObject]$Record
    )

    switch ($Script:settings.DatabaseMode) {
        'Folder' {
            $path = Join-Path $Script:settings.DatabaseURI "$($Record.Node.Name.ToLower()).json"
            $Record | ConvertTo-Json -Depth $Script:settings.JsonDepth | Set-Content $path
            break
        }
        'Memory' {
            $Script:data.Add($Record.Node.Name.ToLower(), ($Record | ConvertTo-Json -Depth $Script:settings.JsonDepth))
            break
        }
        'MongoDB' {
            break
        }
    }
}