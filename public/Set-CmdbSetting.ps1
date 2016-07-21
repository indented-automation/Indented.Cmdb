function Set-CmdbSetting {
    # .SYNOPSIS
    #   The settings file must contain everything needed to run the CMDB.
    # .DESCRIPTION
    # .PARAMETER MessageBusMode
    #   Describes how message bus which should be used by the CMDB module.
    #
    #     * Memory - In-memory queues specific to a PowerShell session.
    #     * Folder - Use a folder to act as a queue.
    #     * RabbitMQ - Use RabbitMQ
    #
    #   If the MessageBus is set to Memory the DatabaseMode must be set to either Folder or MongoDB.
    # .PARAMETER MessageBusURI
    #   The MessageBusURI is required unless the MessageBusMode is set to Standalone.
    #
    #   When the message bus mode is set to Folder this must be a valid file system path.
    #
    #   When the message bus mode is set to RabbitMQ this must be a valid RabbitMQ server.
    # .PARAMETER DatabaseMode
    #   The DatabaseMode must be set if the CMDB module is expected to handle data requests.

    param(
        [ValidateSet('Memory', 'Folder', 'RabbitMQ')]
        [String]$MessageBusMode = 'Memory',
    
        [ValidateScript( { Test-Path $_ } )]
        [String]$MessageBusURI,

        [ValidateSet('None', 'Memory', 'Folder', 'MongoDB')]
        [String]$DatabaseMode = 'Memory',

        [ValidateScript( { Test-Path $_ } )]
        [String]$DatabaseURI,

        [ValidateSet('None', 'Normal', 'Agent')]
        [String]$PollerMode = 'Normal',

        [ValidateRange(1, 200)]
        [Int32]$PollerThreads = 20,

        [ValidateRange(1, [Int32]::MaxValue)]
        [Int32]$JsonDepth = 10,

        [ValidateRange(1, 3600)]
        [Int32]$ClientTimeout = 60,

        [Switch]$Save
    )

    $hasChanged = $false
    $psboundparameters.Keys | Where-Object { $_ -ne 'Save' } | ForEach-Object {
        if ($Script:settings.PSObject.Properties.Item($_)) {
            if ($Script:settings.$_ -ne $psboundparameters[$_]) {
                $Script:settings.$_ = $psboundparameters[$_]
                $hasChanged = $true
            }
        } else {
            Add-Member $_ $psboundparameters[$_] -InputObject $Script:settings
        }
    }

    if ($hasChanged -and -not $Save) {
        $Script:settings.IsFileBacked = $false
    }

    if ($Save) {
        $Script:settings.IsFileBacked = $true

        $moduleName = $myinvocation.MyCommand.ModuleName
        $path = "$env:PROGRAMDATA\$($moduleName -replace '\..+$')\$moduleName.json"
        
        $parentDirectory = Split-Path $path -Parent
        if (-not (Test-Path $parentDirectory)) {
            $null = New-Item $parentDirectory -ItemType Directory
        }
        if (Test-Path $parentDirectory) {
            $Script:settings | ConvertTo-Json -Depth $JsonDepth | Set-Content $path
        }
    }

    # Call the initialiser to apply any changes.
    InitializeModule
}