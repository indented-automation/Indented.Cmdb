function PublishImportItem {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Drain the import queue and push items onto the SetData queue.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     21/07/2016 - Chris Dnet - Added LastImport (Date) field to Node.
    #     08/07/2016 - Chris Dent - Created.

    if ($null -ne $Script:importWorkQueue) {
        # Remove completed work items
        $keys = $Script:importWorkQueue.Keys | ForEach-Object { $_ }
        $keys | Where-Object { $Script:importWorkQueue[$_].AsyncState.IsCompleted } | ForEach-Object {
            $workItem = $Script:importWorkQueue[$_]
            $null = $Script:importWorkQueue.Remove($_)
            $Script:queueLength--

            if ($workItem.Host.HadErrors) {
                Write-Verbose -Message ('The Import request for item {0} with ID {1} completed with errors' -f
                    $workItem.Request.Item.Name,
                    $workItem.Request.ID
                )

                $workItem.Host.Streams.Error | ForEach-Object {
                    Write-Error -ErrorRecord $_
                }
            }

            Write-Verbose -Message ('Completed Import request for {0}' -f $workItem.Request.Item.Name)
        }
    }

    if ($null -ne $Script:importOutputQueue) {
        while ($Script:importOutputQueue.IsEmpty -eq $false) {
            $queueItem = New-Object PSObject
            if ($Script:importOutputQueue.TryDequeue([Ref]$queueItem)) {
                $cmdbItemObject = GetCmdbItemObject $queueItem.Item

                # Import matching

                [String]$nodeName = ''
                if ($cmdbItemObject.ImportMatch) {
                    if ($cmdbItemObject.ImportMatch -is [String]) {
                        $nodeName = $queueItem.Data.($cmdbItemObject.ImportMatch)
                    } elseif ($cmdbItemObject.ImportMatch -is [ScriptBlock]) {
                        $_ = $queueItem.Data
                        $nodeName = $cmdbItemObject.ImportMatch.InvokeWithContext($null, (Get-Variable _ -Scope Local))
                    }
                } elseif ($queueItem.Data.Name) {
                    $nodeName = $queueItem.Data.Name
                }
                $nodeName = $nodeName.Trim().ToLower()

                Write-Verbose -Message ('Draining {0} from import work queue for {1}' -f $nodeName, $queueItem.Item.Name)

                if ($nodeName -ne '') {
                    # Rebuild request

                    $request = [PSCustomObject]@{
                        ID   = [Guid]::NewGuid()
                        Node = [PSCustomObject]@{
                            Name       = $nodeName
                            LastImport = (Get-Date)
                        }
                        Item = $queueItem.Item 
                    }

                    AddNodeProperty -PropertyName $cmdbItemObject.CopyToNode -Node $request.Node -Data $queueItem.Data

                    PushQueueItem -Queue SetData -Message ( 
                        [PSCustomObject]@{
                            ID      = $request.ID
                            Request = $request
                            Data    = UpdateObjectStructure -Data $queueItem.Data -ItemPath $request.Item.ItemPath 
                        }
                    )
                } else {
                    Write-Warning -Message ('Unable to create node from the import queue for {0}, the node name is not set.' -f $queueItem.Item.Name)
                }
            }
        }
    }
}