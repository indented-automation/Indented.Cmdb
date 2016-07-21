function InitializeModule {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Module initialisation script.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     06/07/2016 - Chris Dent - Created.

    [CmdletBinding()]
    param( )

    if ($null -eq $Script:settings) {
        Import-CmdbSetting
    }

    try {
        OpenMessageBus
    } catch {
        $pscmdlet.ThrowTerminatingError($_)
    }

    if ($Script:settings.DatabaseMode -eq 'Memory') {
        $Script:data = New-Object System.Collections.Generic.Dictionary"[String,String]"
    }

    # Create the item cache
    $Script:cmdbItems = New-Object System.Collections.Generic.Dictionary"[String,PSObject]"

    # Create a list that can hold event subscription IDs
    $Script:eventSubscriptionID = New-Object System.Collections.Generic.List[Int32]

    OpenRunspacePool
}