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
    #     21/07/2016 - Chris Dent - Added LastImport (Date) field to Node.
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

                foreach ($errorRecord in $workItem.Host.Streams.Error) {
                    Write-Error -ErrorRecord $errorRecord
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
                    Set-CmdbNode -Filter ('Node.Name -eq "{0}"' -f $nodeName) -Document $queueItem.Data -Item $queueItem.Item.Name

                    $properties = @{
                        LastImport = Get-Date
                    }
                    foreach ($property in $cmdbItemObject.CopyToNode) {
                        $properties.Add($property, $queueItem.Data.$property)
                    }
                    Add-CmdbNodeProperty -Filter ('Node.Name -eq "{0}"' -f $nodeName) -Properties $properties
                } else {
                    Write-Warning -Message ('Unable to create node from the import queue for {0}, the node name is not set.' -f $queueItem.Item.Name)
                }
            }
        }
    }
}