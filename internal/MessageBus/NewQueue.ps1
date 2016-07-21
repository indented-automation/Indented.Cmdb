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
                    if (-not (Test-Path $path)) {
                        $null = New-Item $path -ItemType Directory
                    }
                    break
                }
                'Memory' {
                    if ($null -eq $Script:queue) {
                        $Script:queue = @{}
                    }
                    if (-not $Script:queue.Contains($Name)) {
                        $Script:queue.Add($Name, (New-Object System.Collections.Generic.Queue[String]))
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