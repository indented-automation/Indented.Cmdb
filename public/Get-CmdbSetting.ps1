function Get-CmdbSetting {
    # .SYNOPSIS
    #   Get a read-only copy of the settings.
    # .DESCRIPTION
    #   Get the settings for this instance of the CMDB from $env:PROGRAMDATA.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   System.Management.Automation.PSObject
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     06/07/2016 - Chris Dent - Created.

    $Script:settings | Select-Object *
}