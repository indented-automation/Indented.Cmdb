function CmdbItem {
    # .SYNOPSIS
    #   Define a CMDB item.
    # .DESCRIPTION
    #   A CMDB item must define a minimum of a Get key with a script block which may be used to get information.
    # .PARAMETER Configuration
    #   The configuration of the CmdbItem must include a Get statement (as a script block) and may additionally include:
    #
    #     * Properties - A list of properties to retrieve from the specified command.
    #     * Import - A script block defining a command which may be used to import nodes into the CMDB rather than adding data to existing nodes.
    #     * Filter - A script block defining a filter based on node configuration data.
    # .PARAMETER Name
    #   The name of the CmdbItem.
    # .EXAMPLE
    #   CmdbItem BIOS @{
    #       Get = { Get-WmiObject Win32_BIOS -ComputerName $CmdbNode.Name }
    #   }
    #
    #   Get the result of the Get-WmiObject command and save it in the CMDB.
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     11/07/2016 - Chris Dent - Changed InvokeWithContext for the Call operator to allow immediate returns to be removed from a working queue.
    #     01/07/2016 - Chris Dent - Created.

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [String]$Name,

        [Parameter(Mandatory = $true, Position = 2)]
        [Hashtable]$Configuration
    )

    $cmdbItem = [PSCustomObject]$Configuration
    $cmdbItem | Add-Member Name $Name
    $cmdbItem | Add-Member SupportsGet $false
    $cmdbItem | Add-Member SupportsImport $false

    if (-not $Configuration.Contains('Properties')) {
        $cmdbItem | Add-Member Properties '*'
    }

    if ($Configuration.Contains('Get')) {
        $cmdbItem.SupportsGet = $true
    }

    if ($Configuration.Contains('Import')) {
        $cmdbItem.SupportsImport = $true
    }

    return $cmdbItem
}