function NewPSHost {
    # .SYNOPSIS
    #   Internal use.
    # .DESCRIPTION
    #   Allows commands which implement a PS host to be mocked.
    # .INPUTS
    #   None
    # .OUTPUTS
    #   System.Management.Automation.PowerShell
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     12/07/2016 - Chris Dent - Created.

    [PowerShell]::Create()
}