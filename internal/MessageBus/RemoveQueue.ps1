function RemoveQueue {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Remove a queue. Typically a transient queue used to pass data from the data service to a client.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     06/07/2016 - Chris Dent
    
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [String]$Name
    )

    process {
        if ($Name) {
            switch ($Script:settings.MessageBusMode) {
                'Folder' {
                    $path = Join-Path $Script:settings.MessageBusURI $Name
                    if (Test-Path $path) {
                        Remove-Item $path -Force -Confirm:$false
                    }
                    break
                }
                'Memory' {
                    if ($Script:queue.Contains($Name)) {
                        $Script:queue.Remove($Name)
                    }
                    break
                }
                'RabbitMQ' {
                    break
                }
            }
        }
    }
}