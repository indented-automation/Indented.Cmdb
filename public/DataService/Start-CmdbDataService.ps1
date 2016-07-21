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
    #     06/07/2016 - Chris Dent - Created.

    [CmdletBinding()]
    param(
        [Switch]$Foreground
    )

    if ($Script:settings.MessageBusMode -eq 'Memory') {
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            (New-Object InvalidOperationException 'The data service cannot be started with the current message bus.'),
            'InvalidMessageBus',
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $Script:settings.MessageBusMode
        )
        $pscmdlet.ThrowTerminatingError($errorRecord)
    } elseif ($Script:settings.DatabaseMode -eq 'Memory') {
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            (New-Object InvalidOperationException 'The data service cannot be started when using memory only.'),
            'InvalidDatabaseMode',
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $Script:settings.DatabaseMode
        )
        $pscmdlet.ThrowTerminatingError($errorRecord)
    } else {
        $script = '
            if ($Script:settings.MessageBusMode -ne "Memory" -and $Script:settings.DatabaseMode -ne "Memory") {
                while ($true) {
                    ReadSetDataQueue
                    ReadGetDataQueue
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
}