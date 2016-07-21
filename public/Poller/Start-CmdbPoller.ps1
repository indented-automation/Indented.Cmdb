function Start-CmdbPoller {
    # .SYNOPSIS
    #   Start the CMDB poller as a background thread.
    # .DESCRIPTION
    #   Start the poller as a background thread.
    #
    #   Running the poller in the background has a number of requirements:
    #
    #     * The message bus must not be set to Standalone.
    #     * The settings for the CMDB must be file-based (not the default set loaded into memory when the module loads).
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
            (New-Object InvalidOperationException 'The poller cannot be started with the current message bus.'),
            'InvalidMessageBus',
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $Script:settings.MessageBusMode
        )
        Write-Error -ErrorRecord $errorRecord
    } else {
        $script = '
            if ((Get-CmdbSetting).MessageBus -ne "Memory") {
                while ($true) {
                    ReadUpdateQueue
                    ReadImportQueue

                    PublishUpdateItem
                    PublishImportItem
                    
                    Start-Sleep -Seconds 1
                }
            }
        '

        if ($Foreground) {
            & ([ScriptBlock]::Create($script))
        } else {
            $Script:pollerPSHost = [PowerShell]::Create()
            $null = $Script:pollerPSHost.AddCommand('Import-Module').
                    AddParameter('Name', $myinvocation.MyCommand.Module.Path).
                    AddStatement().
                    AddScript($script).
                    BeginInvoke()
        }
    }
}