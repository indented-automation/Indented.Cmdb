function GetRecord {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Get a record from the CMDB.
    # .PARAMETER NodeName
    #   The name of the document to retrieve.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   System.Management.Automation.PSObject
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     14/07/2016 - Chris Dent - Added Where parameter (temporary).
    #     06/07/2016 - Chris Dent - Created.

    param(
        [String]$NodeName,

        [String]$ItemPath,

        [String]$Where
    )

    switch ($Script:settings.DatabaseMode) {
        { $_ -in 'Folder', 'Memory' } {
            $filter = '$_'
            if ($psboundparameters.ContainsKey('ItemPath')) {
                $filter += ' -and $null -ne $_.{0}' -f $ItemPath.Replace('\', '.')
            }
            if ($psboundparameters.ContainsKey('Where')) {
                $filter += ' -and {0}' -f $Where
            }
            $whereFilter = [ScriptBlock]::Create($filter)
        }
        'Folder' {
            $path = Join-Path $Script:settings.DatabaseURI "$($NodeName.ToLower()).json"
            if (Test-Path $path) {
                Get-Content $path -Raw | ConvertFrom-Json | Where-Object $whereFilter
            }
            break
        }        
        'Memory' {
            if ($Script:data.ContainsKey($NodeName.ToLower())) {
                $Script:data[$NodeName.ToLower()] | ConvertFrom-Json | Where-Object $whereFilter
            }
            break
        }
        'MongoDB' {
            break
        }
    }
}