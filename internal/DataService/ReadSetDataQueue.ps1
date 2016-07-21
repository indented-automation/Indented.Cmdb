function ReadSetDataQueue {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Retrieves messages from the SetData queue.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     04/07/2016 - Chris Dent - Created.

    do {
        $queueItem = PopQueueItem -Queue SetData

        if ($queueItem) {
            Write-Verbose -Message ('Updating item {0} for {1}' -f $queueItem.Request.Item.Name, $queueItem.Request.Node.Name)

            $newRecord = [PSCustomObject]@{
                Node = $queueItem.Request.Node
            }

            if ($queueItem.Data -and $queueItem.Request.Item) {
                $itemRoot = $queueItem.Request.Item.ItemPath.Split('\')[0]
                $newRecord | Add-Member $itemRoot $queueItem.Data.$itemRoot 
            }

            $record = GetRecord -NodeName $queueItem.Request.Node.Name
            if ($record) {
                SetRecord -Record $record -NewRecord $newRecord -OverwritePath $queueItem.Request.Item.ItemPath
            } else {
                AddRecord -Record $newRecord
            }
        }
    } until ($null -eq $queueItem)
}