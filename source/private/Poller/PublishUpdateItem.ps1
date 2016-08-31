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

                foreach ($errorRecord in $workItem.Host.Streams.Error) {
                    Write-Error -ErrorRecord $errorRecord
                }
            } else {
                Write-Verbose -Message ('Completed Update request for item {0} on {1}' -f $workItem.Request.Item.Name, $workItem.Request.Node.Name)
            }

            Set-CmdbNode -Filter ('Node.Name -eq "{0}"' -f $workItem.Request.Node.Name) -Document $workItem.Data -Item $workItem.Request.Item.Name 

            $cmdbItemObject = GetCmdbItemObject $workItem.Request.Item
            $properties = @{
                LastUpdate = Get-Date
            }
            foreach ($property in $cmdbItemObject.CopyToNode) {
                $properties.Add($property, $workItem.Data.$property)
            }
            Add-CmdbNodeProperty -Filter ('Node.Name -eq "{0}"' -f $workItem.Request.Node.Name) -Properties $properties
        }
    }
}