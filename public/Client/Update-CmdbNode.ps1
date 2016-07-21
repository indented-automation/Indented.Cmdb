function Update-CmdbNode {
    # .SYNOPSIS
    #   Update a CMDB node.
    # .DESCRIPTION
    #   Creates an asynchronous request to update a CMDB item.
    # .PARAMETER CmdbItem
    #   The list of items to update.
    # .PARAMETER Name
    #   The name of the node to update.#
    # .INPUTS
    #   Sysetm.String
    #   System.String[]
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     04/07/2016 - Chris Dent - Created.

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String]$Name,

        [String[]]$Item
    )

    process {
        if ($Name -match '\*') {
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                (New-Object ArgumentException 'Wild cards are not yet supported'),
                'WildcardNotSupported',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $Name
            )
            $pscmdlet.ThrowTerminatingError($errorRecord)
        }

        if ($psboundparameters.ContainsKey('Item')) {
            $cmdbItems = $Item | ForEach-Object {
                try {
                    Get-CmdbItem -Name $_
                } catch {
                    Write-Error -ErrorRecord $_
                }
            }
        } else {
            $cmdbItems = Get-CmdbItem
        }

        $cmdbItems | ForEach-Object {
            $cmdbItemObject = GetCmdbItemObject $_
            if ($cmdbItemObject.SupportsGet) {
                $request = [PSCustomObject]@{
                    ID   = [Guid]::NewGuid()
                    Node = [PSCustomObject]@{
                        Name = $Name.ToLower()
                    }
                    Item = $_
                }

                Write-Verbose -Message ('{0}: Queuing an update for {1} with ID {2}' -f $Name, $_.ItemPath, $request.ID)

                PushQueueItem -Queue Update -Message $request

                # Handler for memory based message queue
                if ($Script:settings.MessageBusMode -eq 'Memory') {
                    ReadUpdateQueue
                    $workQueueItem = (Get-CmdbWorkQueue).Update[$request.ID.ToString()]

                    # Wait for the job to complete.
                    while ($workQueueItem.Host.InvocationStateInfo.State -in 'NotStarted', 'Running') {
                        Start-Sleep -Seconds 1
                    }

                    PublishUpdateItem
                    ReadSetDataQueue
                }
            }
        }
    }
}