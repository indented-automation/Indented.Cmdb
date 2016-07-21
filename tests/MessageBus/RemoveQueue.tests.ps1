InModuleScope Indented.Cmdb {
    Describe 'RemoveQueue' {
        Context 'Folder queue' {
            $Script:settings = [PSCustomObject]@{
                MessageBusMode = 'Folder'
                MessageBusURI  = 'TestDrive:\MessageBus'
            }
            
            $null = New-Item 'TestDrive:\MessageBus\Test' -ItemType Directory
            $nothing = RemoveQueue -Name 'Test'

            It 'Returns nothing' {
                $nothing | Should BeNullOrEmpty
            }

            It 'Removes a queue folder' {
                Test-Path 'TestDrive:\MessageBus\Test' | Should Be $false
            }

            It 'Does not throw an error if the queue does not exist' {
                Test-Path 'TestDrive:\MessageBus\Test' | Should Be $false
                { NewQueue -Name 'Test' } | Should Not Throw
            }

            It 'Accepts pipeline input' {
                $null = New-Item 'TestDrive:\MessageBus\Other' -ItemType Directory
                'Other' | RemoveQueue
                Test-Path 'TestDrive:\MessageBus\Other' | Should Be $false
            }
        }

        Context 'Memory queue' {
            $Script:settings = [PSCustomObject]@{
                MessageBusMode = 'Memory'
            }

            $Script:queue = @{
                Test = New-Object System.Collections.Generic.Queue[String]
            }

            $nothing = RemoveQueue -Name 'Test'

            It 'Returns nothing' {
                $nothing | Should BeNullOrEmpty
            }

            It 'Removes a queue' {
                $Script:queue | Should BeOfType [Hashtable]
                $Script:queue.Contains('Test') | Should Be $false
            }

            It 'Does not throw an error if the queue does not exist' {
                $Script:queue.Contains('Test') | Should Be $false
                { NewQueue -Name 'Test' } | Should Not Throw
            }

            It 'Accepts pipeline input' {
                $Script:queue.Add('Other', (New-Object System.Collections.Generic.Queue[String]))
                'Other' | RemoveQueue
                $Script:queue.Contains('Other') | Should Be $false
            }
        }

        Context 'RabbitMQ' {

        }
    }
}