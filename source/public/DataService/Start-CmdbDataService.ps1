function Start-CmdbDataService {
    # .SYNOPSIS
    #   Start the CMDB data service as a background thread.
    # .DESCRIPTION
    #   Start the data service as a background thread.
    #
    #   Running the data service in the background has a number of requirements:
    #
    #     * The message bus must not be set to Standalone.
    #     * The settings for the CMDB must be file-based (not the default set loaded into memory when the module loads).
    #     * The CMDB must not be using a memory for storage.
    #
    #   This is a quick-fix until an event based system can be developed.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     31/08/2016 - Deprecated. May return if there are jobs to run against the database (rule-based updates).
    #     06/07/2016 - Chris Dent - Created.

    [CmdletBinding()]
    param(
        [Switch]$Foreground
    )

    $script = '
        if ($Script:settings.MessageBusMode -ne "Memory" -and $Script:settings.DatabaseMode -ne "Memory") {
            while ($true) {
                ReadGetDataQueue
                ReadSetDataQueue

                # Artificial rate limiter until I can move this to event based.
                Start-Sleep -Seconds 1
            }
        }
    '

    if ($Foreground) {
        & ([ScriptBlock]::Create($script))
    } else {
        $Script:dataServicePSHost = NewPSHost
        $null = $Script:dataServicePSHost.AddCommand('Import-Module').
                AddParameter('Name', $myinvocation.MyCommand.Module.Path).
                AddStatement().
                AddCommand('Start-CmdbDataService').
                AddParameter('Foreground', $true).
                BeginInvoke()
    }
}