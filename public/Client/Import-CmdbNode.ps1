function Import-CmdbNode {
    # .SYNOPSIS
    #   Import nodes based on import definitions.
    # .DESCRIPTION
    #   Import data retrived by a CmdbItem into the CMDB.
    # .PARAMETER Item
    #   The item or items to import. 
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     07/07/2016 - Chris Dent - Created.
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String[]]$Item
    )

    $Item | ForEach-Object {
        try {
            $cmdbItem = Get-CmdbItem -Name $_ -ErrorAction Stop
        } catch {
            Write-Error -ErrorRecord $_
        }
        if ($cmdbItem) {
            $cmdbItemObject = GetCmdbItemObject $CmdbItem
            if ($cmdbItemObject.SupportsImport) {
                $request = [PSCustomObject]@{
                    ID   = [Guid]::NewGuid()
                    Item = $cmdbItem
                }

                Write-Verbose -Message ('Queuing an import for {0} with ID {1}' -f $cmdbItem.ItemPath, $request.ID)

                PushQueueItem -Queue Import -Message $request

                # Handler for memory based message queue
                if ($Script:settings.MessageBusMode -eq 'Memory') {
                    ReadImportQueue
                    $workQueueItem = (Get-CmdbWorkQueue).Import[$request.ID.ToString()]

                    # Wait for the job to complete.
                    while ($workQueueItem.Host.InvocationStateInfo.State -in 'NotStarted', 'Running') {
                        Start-Sleep -Seconds 1
                    }

                    PublishImportItem
                    ReadSetDataQueue
                }
            }
        }
    }
}