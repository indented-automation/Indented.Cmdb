function CloseRunspacePool {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Provides a handle to close an open runspace pool.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     04/07/2016 - Chris Dent - Created.

    $Script:runspacePool.Close()
}