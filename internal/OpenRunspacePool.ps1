function OpenRunspacePool {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Create an initial session state and seed it with the functions exposed in this module then create a runspace 
    #   pool.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     21/07/2016 - Chris Dent - SnapIns must be added to the initial session state. Added a handler.
    #     04/07/2016 - Chris Dent - Created

    $initialSessionState = [InitialSessionState]::CreateDefault()

    Get-Command -Module $myinvocation.MyCommand.ModuleName -CommandType Function | ForEach-Object {
        $sessionStateFunctionEntry = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry(
            $_.Name,
            $_.Definition
        )
        $initialSessionState.Commands.Add($sessionStateFunctionEntry)
    }

    # Test for required snap-ins
    $importedSnapIns = @{}
    Get-CmdbItem | ForEach-Object {
        $cmdbItem = GetCmdbItemObject $_
        if ($cmdbItem.ImportPSSnapIn -and -not $importedSnapIns.Contains($cmdbItem.ImportPSSnapIn)) {
            if (Get-PSSnapIn $cmdbItem.ImportPSSnapIn -Registered -ErrorAction SilentlyContinue) {
                $null = $initialSessionState.ImportPSSnapIn($cmdbItem.ImportPSSnapIn, [Ref]$null)
                $importedSnapIns.Add($cmdbItem.ImportPSSnapIn, $null)
            }
        }
    }

    $Script:runspacePool = [RunspaceFactory]::CreateRunspacePool($initialSessionState)
    $null = $Script:runspacePool.SetMaxRunspaces($Script:settings.PollerThreads)
    $Script:runspacePool.Open()
}