function Add-CmdbCustomItem {
    # .SYNOPSIS
    #   Add an arbitrary item to a node in the CMDB.
    # .DESCRIPTION
    #   Not everything can be discovered dynamically, this command allows the creation of arbitrary items on a node in the CMDB.
    # .PARAMETER Data
    #   The object or objects to add.
    # .PARAMETER ItemPath
    #   The item path may be used to develop a hierarchy. By default the canonical name is the same as name and the item will 
    #   be created at the root of the document.
    # .PARAMETER Name
    #   The name of the item to add.
    # .PARAMETER NodeName
    #   The item will be applied to the specified node.
    # .INPUTS
    #   System.Management.Automation.PSObject
    #   System.String
    # .OUTPUTS
    #   None
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     14/07/2016 - Chris Dent - Created.
     
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 1)]
        [String]$NodeName,

        [Parameter(Mandatory = $true, Position = 2)]
        [String]$Name,

        [Parameter(Mandatory = $true, Position = 3)]
        [AllowNull()]
        [PSObject[]]$Data,

        [String]$ItemPath = $Name
    )

    # Build the request object
    PushQueueItem -Queue SetData -Message (
        [PSCustomObject]@{
            ID      = [Guid]::NewGuid()
            Request = [PSCustomObject]@{
                Node = [PSCustomObject]@{
                    Name = $NodeName
                }
                Item = [PSCustomObject]@{
                    Name     = $Name
                    ItemPath = $ItemPath
                }
            }
            Data    = UpdateObjectStructure -Data $Data -ItemPath $ItemPath 
        }
    )

    if ($Script:settings.MessageBusMode -eq 'Memory') {
        ReadSetDataQueue
    }
}