InModuleScope Indented.Cmdb {
    Describe 'Get-CmdbMessageQueue' {
        $Script:queue = @{
            Test = New-Object System.Collections.Generic.Queue[String]
        }

        Context 'Folder queue' {
            $Script:settings = [PSCustomObject]@{
                MessageBusMode = 'Folder'
            }
            
            It 'Returns nothing' {
                Get-CmdbMessageQueue | Should BeNullOrEmpty
            }
        }

        Context 'Memory queue' {
            $Script:settings = [PSCustomObject]@{
                MessageBusMode = 'Memory'
            }

            $queue = Get-CmdbMessageQueue
            
            It 'Returns the queue hashtable' {
                $queue | Should BeOfType [Hashtable]
            }

            It 'Allows access to the Test queue' {
                ,$queue['Test'] | Should BeOfType [System.Collections.Generic.Queue[String]]
            }
        }

        Context 'RabbitMQ' {
            $Script:settings = [PSCustomObject]@{
                MessageBusMode = 'RabbitMQ'
            }
            
            It 'Returns nothing' {
                Get-CmdbMessageQueue | Should BeNullOrEmpty
            }
        }        
    }
}