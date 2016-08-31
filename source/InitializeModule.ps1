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

    # Create the item cache
    $Script:cmdbItems = New-Object System.Collections.Generic.Dictionary"[String,PSObject]"

    if ($null -eq $Script:settings) {
        Import-CmdbSetting
    }

    # A database mode is now mandatory.
    if ($null -eq $Script:settings.DatabaseUri) {
        Write-Warning 'A database URI must be set to retrieve or add data into the CMDB'
    } else {
        try {
            $mongoUrl = [MongoDB.Driver.MongoUrl]$Script:settings.DatabaseUri
            $Script:mongoDBConnection = New-Object Indented.Cmdb.MongoDB(
                $mongoUrl,
                $Script:settings.DatabaseName,
                $Script:settings.CollectionName
            )

            OpenMessageBus
        } catch {
            $pscmdlet.ThrowTerminatingError($_)
        }
    }

    if ($Script:settings.PollerMode -ne 'None') {
        OpenRunspacePool
    }
}