function Get-CmdbData {
    # .SYNOPSIS
    #   Get the content of a memory resident data service.
    # .DESCRIPTION
    #   Get-CmdbData provides direct access to a memory-resident data service.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   System.Collections.Generic.Dictionary[String,String]
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     07/07/2016 - Chris Dent - Created.

    if ($Script:settings.DatabaseMode -eq 'Memory') {
        return $Script:data
    }
}