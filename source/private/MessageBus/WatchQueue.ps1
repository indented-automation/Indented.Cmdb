function WatchQueue {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Adds the FileSystemWatcher to a queue, at the moment exclusively for use by Get-CmdbNode to control ordering of data recieved.
    # .PARAMETER Name
    #   The name of the queue to subscribe to.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   System.Management.Automation.PSEventJob
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     31/08/2016 - Chris Dent - Deprecated.
    #     14/07/2016 - Chris Dent - Created.
    
    param(
        [String]$Name
    )

    if (TestQueue -Name $Name) {
        switch ($Script:settings.MessageBusMode) {
            'Folder' {
                # This is a partial implementation of the file system watcher.
                # It will, at some point, be implemented for the Poller and DataService. Just not now as it takes too long.

                $path = Join-Path $Script:settings.MessageBusURI $Name

                $fileSystemWatcher = New-Object System.IO.FileSystemWatcher($path, '*.json')
                $fileSystemWatcher.NotifyFilter = 'LastWrite'

                Register-ObjectEvent -InputObject $fileSystemWatcher -EventName 'Changed' -Action {
                    # Guard against the second event caused by how Windows will save data to this file.
                    if (Test-Path $eventArgs.FullPath) {
                        Get-Content $eventArgs.FullPath -Raw | ConvertFrom-Json
                        Remove-Item $eventArgs.FullPath
                    }
                }
            }
            'RabbitMQ' {
                # Not implemented
            }
        }
    }
}