InModuleScope Indented.Cmdb {
    Describe 'Set-CmdbNode' {
        $Script:settings = [PSCustomObject]@{
            MessageBusMode = 'Folder'
        }
        $Script:message = $null
        
        Mock PushQueueItem {
            $Script:message = $Message
        }
        Mock ReadSetDataQueue { }

        $defaultParams = @{
            Name       = 'somenodename'
            Agent      = 'someagent'
            AgentItems = 'Hardware\*'
        }

        It 'Returns nothing' {
            Set-CmdbNode @defaultParams | Should BeNullOrEmpty
        }

        It 'Builds NodeData from passed parameters' {
            Set-CmdbNode @defaultParams
            $Script:message.Request.Node.Agent | Should Be 'someagent'
            $Script:message.Request.Node.AgentItems | Should Be 'Hardware\*'
        }

        It 'Accepts a hashtable as NodeData' {
            Set-CmdbNode -NodeData @{
                Name         = 'somenodename'
                SomeProperty = 'somevalue'
            }
            $Script:message.Request.Node.SomeProperty | Should Be 'somevalue'
        }

        It 'Overwrites any value for Name in NodeData with the value from the Name parameter' {
            Set-CmdbNode -Name 'somenodename' -NodeData @{
                Name         = 'someothername'
                SomeProperty = 'somevalue'
            }
            $Script:message.Request.Node.Name | Should Be 'somenodename'
        }

        It 'Accepts $null arguments for parameters' {
            Set-CmdbNode -Name 'somenodename' -Agent $null
            $Script:message.Request.Node.Agent | Should BeNullOrEmpty
        }

        Context 'Invalid NodeData' {
            It 'Throws a terminating error if Name is supplied at all' {
                try {
                    Set-CmdbNode -NodeData @{SomeProperty = 'somevalue'} 
                } catch {
                    $errorID = $_.FullyQualifiedErrorID
                }
                $errorID | Should Be 'NodeNameNotSet,Set-CmdbNode'
            }

            It 'Throws a termating error if NodeData built from parameters contains no values which can be set' {
                try {
                    Set-CmdbNode -Name 'somenodename' 
                } catch {
                    $errorID = $_.FullyQualifiedErrorID
                }
                $errorID | Should Be 'NoValuesToSet,Set-CmdbNode'
            }

            It 'Throws a terminating error if the NodeData parameter contains no values which can be set' {
                try {
                    Set-CmdbNode -NodeData @{Name = 'somenodename'} 
                } catch {
                    $errorID = $_.FullyQualifiedErrorID
                }
                $errorID | Should Be 'NoValuesToSet,Set-CmdbNode'
            }
        }

        Context 'Memory based message bus' {
            It 'Does not attempt call data service functions when the message bus node is not set to Memory' {
                Set-CmdbNode @defaultParams
                Assert-MockCalled ReadSetDataQueue -Exactly 0 -Scope It
            }

            $Script:settings.MessageBusMode = 'Memory'

            It 'Calls functions from the data service if the message bus is held in memory' {
                Set-CmdbNode @defaultParams
                Assert-MockCalled ReadSetDataQueue -Exactly 1 -Scope It
            }

            $Script:settings.MessageBusMode = 'Folder'
        }
    }
}