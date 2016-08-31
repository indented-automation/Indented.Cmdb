function GetDefaultSettings {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   The default settings for the CMDB configure the current node as a standalone service using memory for everything.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   System.Management.Automation.PSObject
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     22/07/2016 - Chris Dent - Added GetDataPageSize.
    #     14/07/2016 - Chris Dent - Created.

    [PSCustomObject]@{
        MessageBusMode       = 'Memory'
        MessageBusURI        = $null
        DatabaseMode         = 'MongoDB'
        DatabaseURI          = $null
        PollerMode           = 'None'
        PollerThreads        = 20
        CmdbItemPath         = Join-Path $myinvocation.MyCommand.Module.ModuleBase 'examples\cmdbitems'
        PollerMaxQueueLength = 40
        JsonDepth            = 10
        ClientTimeout        = 60
        IsFileBacked         = $false
        DatabaseName         = 'CMDB'
        CollectionName       = 'nodeData'
    }
}