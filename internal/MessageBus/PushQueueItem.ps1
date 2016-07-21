function PushQueueItem {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Add an item to the specified message bus queue.
    # .PARAMETER Message
    #   The message value to add to the queue.
    # .PARAMETER Queue
    #   The name of the queue.
    # .INPUTS
    #   System.String
    #   System.Management.Automation.PSObject
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     06/07/2016 - Chris Dent - Created.

    param(
        [String]$Queue,

        [Object]$Message
    )

    $messageJson = $Message | ConvertTo-Json -Depth $Script:settings.JsonDepth

    switch ($script:settings.MessageBusMode) {
        'Folder' {
            $path = [System.IO.Path]::Combine(
                $script:settings.MessageBusURI,
                $Queue,
                "$($Message.ID).json"
            )
            $parentPath = Split-Path $path -Parent
            if (Test-Path $parentPath) {
                $messageJson | Set-Content $path
            }
            break
        }
        'Memory' {
            if ($Script:queue.Contains($Queue)) {
                $null = $Script:queue[$Queue].Enqueue($messageJson)
            }
            break
        }        
        'RabbitMQ' {
            break
        }
    }
}