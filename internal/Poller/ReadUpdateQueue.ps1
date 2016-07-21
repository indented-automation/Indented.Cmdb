function ReadUpdateQueue {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Takes items from the Update queue and queues execution in the runspace pool on this host.
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

    if ($Script:updateWorkQueue -eq $null) {
	    $Script:updateWorkQueue = New-Object System.Collections.Generic.Dictionary"[String,PSObject]"
    }
    if ($null -eq $Script:queueLength -or $Script:queueLength -lt 0) {
        $Script:queueLength = 0
    }

    do {
        if ($Script:queueLength -gt $Script:settings.PollerMaxQueueLength) {
            # Ignore this queue for a while, do something else.
            $request = $null
        } else {
            $request = PopQueueItem -Queue Update
        }

        if ($request) {
            Write-Verbose -Message ('Received Update request for item {0} on {1}' -f $request.Item.Name, $request.Node.Name)
            
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
                        $InternalNode,

                        $InternalItem
                    )

                    $Global:Item = . $InternalItem.Path
                    $Global:Node = $InternalNode

                    & $Global:Item.Get | Select-Object $Global:Item.Properties

                    Remove-Variable Item -Scope Global
                    Remove-Variable Node -Scope Global
                '

                $inDataCollection = New-Object System.Management.Automation.PSDataCollection[PSObject]
                $outDataCollection = New-Object System.Management.Automation.PSDataCollection[PSObject]
                $psHost = [PowerShell]::Create()
                $psHost.RunspacePool = $Script:runspacePool

                $null = $psHost.AddScript($Script).
                                AddParameter('InternalNode', $request.Node).
                                AddParameter('InternalItem', $request.Item)

                $Script:queueLength++
                $null = $Script:updateWorkQueue.Add(
                    $request.ID,
                    [PSCustomObject]@{
                        Request    = $request
                        Host       = $psHost
                        AsyncState = $psHost.BeginInvoke($inDataCollection, $outDataCollection)
                        Data       = $outDataCollection
                    }
                )
            }
        }
    } until ($null -eq $request)
}