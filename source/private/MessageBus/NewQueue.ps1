function NewQueue {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Create a new queue. Typically a transient queue used to pass data from the data service to a client.
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
        [String[]]$Name
    )

    foreach ($thisName in $Name) {
        switch ($Script:settings.MessageBusMode) {
            'Folder' {
                $path = Join-Path $Script:settings.MessageBusURI $thisName
                if (-not (Test-Path $path)) {
                    $null = New-Item $path -ItemType Directory
                }
                break
            }
            'RabbitMQ' {
                break   
            }
        }
    }
}