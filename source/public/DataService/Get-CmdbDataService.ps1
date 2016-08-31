function Get-CmdbDataService {
    # .SYNOPSIS
    #   Gets the poller host.
    # .DESCRIPTION
    #   Allows access to the poller host.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   System.Management.Automation.PowerShell
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     06/07/2016 - Chris Dent - Created.

    return $Script:dataServicePSHost
}