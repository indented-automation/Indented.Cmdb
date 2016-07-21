function PublishUpdateItem {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Drain the update queue and push items onto the SetData queue.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     21/07/2016 - Chris Dnet - Added LastUpdate (Date) field to Node.
    #     08/07/2016 - Chris Dent - Split Import logic to a different working queue.
    #     04/07/2016 - Chris Dent - Created.

    if ($null -ne $Script:updateWorkQueue) {
        $keys = $Script:updateWorkQueue.Keys | ForEach-Object { $_ }
        $keys | Where-Object { $Script:updateWorkQueue[$_].AsyncState.IsCompleted } | ForEach-Object {
            $workItem = $Script:updateWorkQueue[$_]
            $null = $Script:updateWorkQueue.Remove($_)
            $Script:queueLength--

            if ($workItem.Host.HadErrors) {
                Write-Verbose -Message ('The Update request for item {0} on {1} with ID {2} completed with errors' -f
                    $workItem.Request.Item.Name,
                    $workItem.Request.Node.Name,
                    $workItem.Request.ID
                )

                $workItem.Host.Streams.Error | ForEach-Object {
                    Write-Error -ErrorRecord $_
                }
            } else {
                Write-Verbose -Message ('Completed Update request for item {0} on {1}' -f $workItem.Request.Item.Name, $workItem.Request.Node.Name)
            }

            $cmdbItemObject = GetCmdbItemObject $workItem.Request.Item
            AddNodeProperty -PropertyName $cmdbItemObject.CopyToNode -Node $workItem.Request.Node -Data $workItem.Data
            $workItem.Request.Node | Add-Member 'LastUpdate' (Get-Date) -Force

            PushQueueItem -Queue SetData -Message ( 
                [PSCustomObject]@{
                    ID      = $workItem.Request.ID
                    Request = $workItem.Request
                    Data    = UpdateObjectStructure -Data $workItem.Data -ItemPath $workItem.Request.Item.ItemPath 
                }
            )
        }
    }
}