function ReadGetDataQueue {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Retrieves messages from the GetData queue.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     08/07/2016 - Chris Dent - Allowed selection of specific document items.
    #     04/07/2016 - Chris Dent - Created.

    do {
        $request = PopQueueItem -Queue GetData

        if ($request) {
            Write-Verbose -Message ('Received GetData request for {0}' -f $request.NodeName)

            # GetRecord needs to be able to filter.
            $params = @{
                NodeName = $request.NodeName
            }
            if ($null -ne $request.ItemPath -and $request.ItemPath -ne [String]::Empty) {
                $params.Add('ItemPath', $request.ItemPath)
            }
            if ($null -ne $request.Where -and $request.Where -ne [String]::Empty) {
                $params.Add('Where', $request.Where)
            }

            $recordCount = 0
            GetRecord @params | ForEach-Object {
                $recordCount++

                Write-Verbose -Message ('  Returning record for {0}' -f $_.Node.Name)

                $currentRecord = $_
                # It may be sensible to make GetRecord deal with item expansion (depending on MongoDB). This is a start though.
                if ($null -eq $request.ItemPath -or $request.ItemPath -eq [String]::Empty) {
                    $value = $currentRecord
                } else {
                    Write-Verbose -Message ('    Expanding item {0}' -f $request.ItemPath)

                    $return = $currentRecord
                    $request.ItemPath.Split('\') | ForEach-Object {
                        $return = $return.$_
                    }
                    $value = $return
                }

                $value | Add-Member 'NodeName' $currentRecord.Node.Name

                # Should consider merging into batches.
                PushQueueItem -Queue $request.ID -Message (
                    [PSCustomObject]@{
                        ID    = [Guid]::NewGuid()
                        Name  = $request.NodeName
                        Value = $value 
                    }
                )
            }

            if ($Script:settings.MessageBusMode -eq 'Folder') {
                # Sleep for 1 second to attempt to ensure completion is the last thing in the queue
                Start-Sleep -Seconds 1
            }

            Write-Verbose -Message '  Pushing completion notification'

            PushQueueItem -Queue $request.ID -Message (
                [PSCustomObject]@{
                    ID    = $request.ID
                    Name  = $request.NodeName
                    Value = $request.ID
                }
            )
        }
    } until ($null -eq $request)
}