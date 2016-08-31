function NewInitialSessionState {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Create a session state that exposes the non-public commands in this module.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   System.Management.Automation.Runspaces.InitialSessionState
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     22/07/2016 - Chris Dent - Created.

    $initialSessionState = [InitialSessionState]::CreateDefault()

    Get-Command -Module $myinvocation.MyCommand.ModuleName -CommandType Function | ForEach-Object {
        $sessionStateFunctionEntry = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry(
            $_.Name,
            $_.Definition
        )
        $initialSessionState.Commands.Add($sessionStateFunctionEntry)
    }

    return $initialSessionState
}