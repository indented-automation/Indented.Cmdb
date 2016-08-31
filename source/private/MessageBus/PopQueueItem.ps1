function PopQueueItem {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Get an item from the specified message bus queue.
    # .PARAMETER Queue
    #   The name of the queue.
    # .INPUTS
    #   System.String
    # .OUTPUTS
    #   System.Management.Automation.PSObject
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     22/07/2016 - Chris Dent - Immediately removes a file from the queue for "offline" processing.
    #     11/07/2016 - Chris Dent - Added failure "queue".
    #     06/07/2016 - Chris Dent - Created.

    param(
        [String]$Queue
    )

    switch ($Script:settings.MessageBusMode) {
        'Folder' {
            $path = [System.IO.Path]::Combine(
                $Script:settings.MessageBusURI,
                $Queue
            )
            $failedMessagePath = [System.IO.Path]::Combine(
                $Script:settings.MessageBusURI,
                'Failed'
            )

            if (Test-Path $path) {
                # Better, but queue sharing is still pretty awful. At present a limitation on how fast I can enact this command.
                $file = Get-ChildItem $path -Filter *.json | Select-Object -First 1 | Move-Item -Destination $env:TEMP -PassThru

                if ($file) {
                    $isValidJson = $true
                    $hadReadError = $false
                    try {
                        Get-Content $file.FullName -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                    } catch [System.IO.IOException] {
                        # Do nothing, allow it to be re-processed next time this is called.
                        $hadReadError = $true
                    } catch {
                        $isValidJson = $false
                        if ($hadReadError -eq $false) {
                            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                                (New-Object InvalidOperationException ('An attempt to read from the message bus failed. ({0})' -f $_.Exception.Message)),
                                'DequeueFailed',
                                [System.Management.Automation.ErrorCategory]::InvalidOperation,
                                $file
                            )
                            Write-Error -ErrorRecord $errorRecord
                        }
                    }

                    if (-not $hadReadError) {
                        if ($isValidJson) {
                            Remove-Item $file.FullName
                        } else {
                            Move-Item $file.FullName $failedMessagePath 
                        }
                    }
                }
            }
            break
        }
        'RabbitMQ' {
            break
        }
    }
}