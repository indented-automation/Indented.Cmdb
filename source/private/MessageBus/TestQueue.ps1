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

    param(
        [String]$Name
    )

    switch ($Script:settings.MessageBusMode) {
        'Folder' {
            $path = Join-Path $Script:settings.MessageBusURI $Name
            Test-Path $path
            break
        }
        'RabbitMQ' {
            break   
        }
    }
}