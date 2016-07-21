function Set-CmdbNode {
    # .SYNOPSIS
    #   Set the configuration data for a CMDB node.
    # .DESCRIPTION
    #   ConfigurationData is a hash table representing any static information that should be recorded about the node.
    #
    #   For example, ConfigurationData may include a site or a role.
    #
    #   Configuration data is made available to Get and Filter blocks using the reserved variable CmdbNode.
    #
    #   The Node also stores a number of specialised fields:
    #
    #     Name - Mandatory, the name of the record.
    #     Agent - Used where harvesting information should be offloaded to another host. For example, when the network subnet cannot be reached.
    #
    # .PARAMETER ConfigurationData
    #   A hashtable containing any information that should be recorded with the node.
    # .PARAMETER Name
    #   The name of an existing CMDB node.
    # .NOTES
    #   Author: Chris Dent
    #
    #   Change log:
    #     12/07/2016 - Chris Dent - Created.

    [CmdletBinding(DefaultParameterSetName = 'FromParameters')]
    param(
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'FromParameters')]
        [Parameter(ParameterSetName = 'FromNodeData')]
        [String]$Name,

        [Parameter(ParameterSetName = 'FromParameters')]
        [AllowNull()]
        [String]$Agent,

        [Parameter(ParameterSetName = 'FromParameters')]
        [AllowNull()]
        [String[]]$AgentItems,

        [Parameter(Mandatory = $true, ParameterSetName = 'FromNodeData')]
        [Hashtable]$NodeData
    )

    if ($pscmdlet.ParameterSetName -eq 'FromNodeData') {
        if ($psboundparameters.ContainsKey('Name')) {
            $NodeData.Name = $Name
        }
        if (-not $NodeData.Contains('Name')) {
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                (New-Object ArgumentException 'A value for Name must be provided in the Node Data'),
                'NodeNameNotSet',
                [System.Management.Automation.ErrorCategory]::InvalidArgument,
                $NodeData
            )
            $pscmdlet.ThrowTerminatingError($errorRecord)
        }
    } elseif ($pscmdlet.ParameterSetName -eq 'FromParameters') {
        $NodeData = @{}
        $psboundparameters.Keys | ForEach-Object {
            $NodeData.Add($_, $psboundparameters[$_])
        }
    }

    # Verify there's something here other than name
    if ($null -eq ($NodeData.Keys | Where-Object { $_ -ne 'Name' })) {
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            (New-Object ArgumentException 'Node data does not contain any values which may be set'),
            'NoValuesToSet',
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            $NodeData
        )
        $pscmdlet.ThrowTerminatingError($errorRecord)
    }

    Write-Verbose -Message ('{0}: Queuing a node data update with ID {1}' -f $Name, $request.ID)

    PushQueueItem -Queue SetData -Message ( 
        [PSCustomObject]@{
            ID      = [Guid]::NewGuid()
            Request = [PSCustomObject]@{
                Node = [PSCustomObject]$NodeData
            }
            Data    = $null
        }
    )

    if ($Script:settings.MessageBusMode -eq 'Memory') {
        ReadSetDataQueue
    }
}