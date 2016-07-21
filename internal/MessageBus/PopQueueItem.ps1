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
                $file = Get-ChildItem $path -Filter *.json | Select-Object -First 1

                if ($file) {
                    $isValidJson = $true
                    $hadReadError = $false
                    try {
                        (Get-Content $file.FullName -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop)
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
        'Memory' {
            if ($Script:queue.Contains($Queue) -and $Script:queue[$Queue].Count -gt 0) {
                try {
                    $Script:queue[$Queue].Dequeue() | ConvertFrom-Json
                } catch {
                    Write-Error -ErrorRecord $_
                }
            }
            break
        }
        'RabbitMQ' {
            break
        }
    }
}