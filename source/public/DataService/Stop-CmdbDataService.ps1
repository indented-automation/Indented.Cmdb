function Stop-CmdbDataService {
    # .SYNOPSIS
    #   Stop a background CMDB data service.
    # .DESCRIPTION
    #   Stop the data service running in a background thread.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     06/07/2016 - Chris Dent - Created.

    if ($null -ne $Script:dataServicePSHost) {
        $Script:dataServicePSHost.Stop()
        $Script:dataServicePSHost.Dispose()
    }
}