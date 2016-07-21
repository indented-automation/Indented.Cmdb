function Get-CmdbNode {
    # .SYNOPSIS
    #   Get a CMDB node and its configuration data.
    # .DESCRIPTION
    #   Get an existing CMDB item from the CMDB store.
    # .PARAMETER Item
    #   Get a specific item. If a specific item is requested the data service will attempt to return only the most specific objects. 
    # .PARAMETER Name
    #   Get a specific node by name.
    # .PARAMETER TimeOut
    #   Timeout the request to the data service after a number of seconds with no response from the service.
    # .PARAMETER Where
    #   A temporary parameter to allow data-service side filtering. Insecure as the script block is executed without testing.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   System.Management.Automation.PSObject
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     14/07/2016 - Chris Dent - Added file system watcher based queue handler. Added Where parameter.
    #     04/07/2016 - Chris Dent - Created. 

    [CmdletBinding()]
    param(
        [String]$Name = '*',

        [String]$Item = '',

        [String]$Where = '',

        [Int32]$Timeout = $Script:settings.ClientTimeout
    )

    $request = [PSCustomObject]@{
        ID       = [Guid]::NewGuid().ToString()
        NodeName = $Name
        ItemPath = $Item
        Where    = $Where
    }

    if ($psboundparameters.ContainsKey('Item')) {
        try {
            $cmdbItem = Get-CmdbItem -Name $Item -ErrorAction SilentlyContinue
        }  catch {
            $pscmdlet.ThrowTerminatingError($_)
        }
        if ($cmdbItem) {
            $request.ItemPath = $cmdbItem.ItemPath
        }
    }

    NewQueue -Name $request.ID

    PushQueueItem -Queue GetData -Message $request

    # Handler for memory based message queue
    if ($Script:settings.MessageBusMode -eq 'Memory') {
        ReadGetDataQueue
    }

    if ($Script:settings.MessageBusMode -eq 'Folder') {
        # This is a bit of a bodge until I can spend the time to do better.
        $eventJob = WatchQueue -Name $request.ID

        do {
            if ($eventJob.HasMoreData) {
                $i = 0
                $eventJob | Receive-Job | ForEach-Object {
                    $response = $_

                    if ($response.Value -eq $request.ID) {
                        $isComplete = $true
                    } else {
                        $hasValue = $true
                        $response.Value
                    }
                }
                # HasMoreData isn't exactly quick to update. This just avoids (some) calls made to Receive-Job.
                Start-Sleep -Milliseconds 200
            } else {
                $i++
                Start-Sleep -Seconds 1
            }
        } until ($isComplete -or $i -ge $Timeout)

        Unregister-Event -SubscriptionId $eventJob.ID
        Remove-Job -ID $eventJob.ID
    } else {
        $i = 0
        $isComplete = $hasValue = $false
        do {
            $response = PopQueueItem -Queue $request.ID
            if ($null -eq $response) {
                $i++
                Start-Sleep -Seconds 1
            } else {
                # Reset the timeout
                $i = 0
                if ($response.Value -eq $request.ID) {
                    $isComplete = $true
                } else {
                    $hasValue = $true
                    $response.Value
                }
            }
        } until ($isComplete -or $i -ge $Timeout)
    }

    if ($i -ge $Timeout) {
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            (New-Object TimeoutException 'The request timed out'),
            'GetDataTimeout',
            [System.Management.Automation.ErrorCategory]::OperationTimeout,
            $Name
        )
        Write-Error -ErrorRecord $errorRecord
    } else {
        if (-not $hasValue) {
            Write-Warning -Message ('The request for {0} was successful, but no data was available.' -f $Name) 
        }
    }

    RemoveQueue -Name $request.ID
}