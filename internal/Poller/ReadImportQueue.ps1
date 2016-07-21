function ReadImportQueue {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Takes items from the Import queue and queues execution in the runspace pool on this host.
    #
    #   Output from the executing command is pushed to a concurrent queue which is immediately drained and 
    #   sent to the data service.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     11/07/2016 - Chris Dent - Renamed internal script variables to prevent problems caused when the method declaration deletes global level variables.
    #     04/07/2016 - Chris Dent - Created. 

    if ($null -eq $Script:importWorkQueue) {
	    $Script:importWorkQueue = New-Object System.Collections.Generic.Dictionary"[String,PSObject]"
    }
    if ($null -eq $Script:importOutputQueue) {
        $Script:importOutputQueue = New-Object System.Collections.Concurrent.ConcurrentQueue[PSObject]
    }
    if ($null -eq $Script:queueLength -or $Script:queueLength -lt 0) {
        $Script:queueLength = 0
    }

    do {
        if ($Script:queueLength -gt $Script:settings.PollerMaxQueueLength) {
            # Ignore this queue for a while, do something else.
            $request = $null
        } else {
            $request = PopQueueItem -Queue Import
        }

        if ($request) {
            Write-Verbose -Message ('Received Import request for {0}' -f $request.Item.Name)

            # Rewrite Item to be relative to this node.
            try {
                $request.Item = Get-CmdbItem -ItemPath $request.Item.ItemPath -ErrorAction Stop
            } catch {
                Write-Error -ErrorRecord $_
                $request.Item = $null
            }

            if ($request.Item) {
                $script = '
                    param(
                        $InternalItem,

                        $ImportOutputQueue
                    )

                    $Global:Item = . $InternalItem.Path

                    & $Global:Item.Import | ForEach-Object {
                        $ImportOutputQueue.Enqueue(
                            [PSCustomObject]@{
                                Item = $InternalItem
                                Data = $_ | Select-Object $Global:Item.Properties
                            }
                        )
                    }

                    Remove-Variable Item -Scope Global
                '

                $psHost = NewPSHost
                $psHost.RunspacePool = $Script:runspacePool

                $null = $psHost.AddScript($script).
                                AddParameter('InternalItem', $request.Item).
                                AddParameter('ImportOutputQueue', (,$Script:importOutputQueue))

                $Script:queueLength++
                $null = $Script:importWorkQueue.Add(
                    $request.ID,
                    [PSCustomObject]@{
                        Request        = $request
                        Host           = $psHost
                        AsyncState     = $psHost.BeginInvoke()
                    }
                )
            }
        }
    } until ($null -eq $request)
}