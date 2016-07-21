function Stop-CmdbPoller {
    # .SYNOPSIS
    #   Stop a background CMDB poller.
    # .DESCRIPTION
    #   Stop the poller running in a background thread.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     06/07/2016 - Chris Dent - Created.

    if ($null -ne $Script:pollerPSHost) {
        $Script:pollerPSHost.Stop()
        $Script:pollerPSHost.Dispose()
    }
}