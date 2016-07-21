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
    #     14/07/2016 - Chris Dent - Created.

    [PSCustomObject]@{
            MessageBusMode       = 'Memory'
            MessageBusURI        = $null
            DatabaseMode         = 'Memory'
            DatabaseURI          = $null
            PollerMode           = 'Normal'
            PollerThreads        = 20
            PollerMaxQueueLength = 40
            JsonDepth            = 10
            ClientTimeout        = 60
            IsFileBacked         = $false
        }
}