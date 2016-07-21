function Get-CmdbWorkQueue {
    # .SYNOPSIS
    #   Get the work queue.
    # .DESCRIPTION
    #   The work queue is populated by the poller, it contains threads which are executing and threads which are waiting to execute.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   System.Collections.Generic.Dictionary[String,PSObject]
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     06/07/2016 - Chris Dent - Created.

    return [PSCustomObject]@{
        Import = $Script:importWorkQueue
        Update = $Script:updateWorkQueue
    }
}