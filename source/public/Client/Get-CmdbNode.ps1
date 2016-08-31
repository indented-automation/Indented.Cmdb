function Get-CmdbNode {
    # .SYNOPSIS
    #   Get a CMDB node and its configuration data.
    # .DESCRIPTION
    #   Get an existing CMDB item from the CMDB store.
    # .PARAMETER Filter
    #   A script block or string filter which will be converted into a MongoDB style filter.
    #
    #   Comparison operators:
    #
    #   Logic operators:
    #
    # .PARAMETER Item
    #   Get a specific item. If a specific item is requested the data service will attempt to return only the most specific objects. 
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   System.Management.Automation.PSObject
    # .EXAMPLE
    # 
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     14/07/2016 - Chris Dent - Added file system watcher based queue handler. Added Filter parameter.
    #     04/07/2016 - Chris Dent - Created. 

    [CmdletBinding()]
    param(
        [Parameter(Position = 1)]
        [String]$Filter,

        [String]$Item
    )

    if ($psboundparameters.ContainsKey('Item')) {
        $cmdbItem = Get-CmdbItem $Item -ErrorAction SilentlyContinue
        # Need to add wildcard support
        if ($null -ne $cmdbItem) {
            $Item = $cmdbItem.Name
        }
    }

    if ($psboundparameters.ContainsKey('Filter')) {
        if ($Filter.IndexOf(' ') -eq -1) {
            # Assume Filter is a node name and use it.
            $Filter = 'Node.Name -eq "{0}"' -f $Filter.ToLower()
        }
        try {
            $Filter = ConvertToMongoDBFilter $Filter -ErrorAction Stop | ConvertTo-Json -Compress -Depth 10
            $Script:mongoDBConnection.FindDocument($Filter) | ConvertFrom-Json | ExpandItem -Name $Item | ConvertToDate
        } catch {
            $pscmdlet.ThrowTerminatingError($_)
        }
    } else {
        try {
            $Script:mongoDBConnection.FindDocument() | ConvertFrom-Json | ExpandItem -Name $Item | ConvertToDate
        } catch {
            $pscmdlet.ThrowTerminatingError($_)
        }
    }
}