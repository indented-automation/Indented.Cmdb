InModuleScope Indented.Cmdb {
    Describe 'NewQueue' {
        Context 'Folder queue' {
            $Script:settings = [PSCustomObject]@{
                MessageBusMode = 'Folder'
                MessageBusURI  = 'TestDrive:\MessageBus'
            }
            
            $nothing = NewQueue -Name 'Test'

            It 'Returns nothing' {
                $nothing | Should BeNullOrEmpty
            }

            It 'Creates a queue folder' {
                Test-Path 'TestDrive:\MessageBus\Test' | Should Be $true
            }

            It 'Does not throw an error if the queue already exists' {
                Test-Path 'TestDrive:\MessageBus\Test' | Should Be $true
                { NewQueue -Name 'Test' } | Should Not Throw
            }

            It 'Accepts pipeline input' {
                'Other' | NewQueue
                Test-Path 'TestDrive:\MessageBus\Other' | Should Be $true
            }
        }

        Context 'Memory queue' {
            $Script:settings = [PSCustomObject]@{
                MessageBusMode = 'Memory'
            }

            $nothing = NewQueue -Name 'Test'

            It 'Returns nothing' {
                $nothing | Should BeNullOrEmpty
            }

            It 'Creates a queue' {
                $Script:queue | Should BeOfType [Hashtable]
                $Script:queue.Contains('Test') | Should Be $true
            }

            It 'Does not throw an error if the queue already exists' {
                $Script:queue.Contains('Test') | Should Be $true
                { NewQueue -Name 'Test' } | Should Not Throw
            }

            It 'Accepts pipeline input' {
                'Other' | NewQueue
                $Script:queue.Contains('Other') | Should Be $true
            }
        }

        Context 'RabbitMQ' {

        }        
    }
}