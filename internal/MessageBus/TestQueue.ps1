function TestQueue {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Get a list of queues.
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
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String]$Name
    )

    process {
        if ($Name) {
            switch ($Script:settings.MessageBusMode) {
                'Folder' {
                    $path = Join-Path $Script:settings.MessageBusURI $Name
                    Test-Path $path
                    break
                }
                'Memory' {
                    $Script:queue.Contains($Name)
                    break
                }
                'RabbitMQ' {
                    break   
                }
            }
        }
    }
}