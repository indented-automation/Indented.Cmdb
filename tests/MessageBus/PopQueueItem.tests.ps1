InModuleScope Indented.Cmdb {
    Describe 'PopQueueItem' {
        $message = '{ "Message": "Hello world" }'

        Context 'Folder queue' {
            $Script:settings = [PSCustomObject]@{
                MessageBusMode = 'Folder'
                MessageBusURI  = 'TestDrive:\MessageBus'
            }

            $null = New-Item 'TestDrive:\MessageBus\Test' -ItemType Directory
            $message | Set-Content 'TestDrive:\MessageBus\Test\message.json'

            $queueItem = PopQueueItem -Queue 'Test'

            It 'Returns an item from the queue' {
                $queueItem | Should Not BeNullOrEmpty
            }

            It 'Returns a PSObject representing the JSON text' {
                $queueItem | Should BeOfType [PSObject]
                $queueItem.Message | Should Be 'Hello world'
            }

            It 'Does not throw an error if the queue is empty' {
                Test-Path 'TestDrive:\MessageBus\Test\*.json' | Should Be $false
                { PopQueueItem 'Test' } | Should Not Throw
            }

            It 'Does not throw an error if the queue does not exist' {
                Test-Path 'TestDrive:\MessageBus\Other' | Should Be $false
                { PopQueueItem 'Other' } | Should Not Throw
            }
        }

        Context 'RabbitMQ' {

        }

        Context 'Memory queue' {
            $Script:settings = [PSCustomObject]@{
                MessageBusMode = 'Memory'
            }

            $Script:queue = @{
                Test = New-Object System.Collections.Generic.Queue[String]
            }
            $Script:queue['Test'].Enqueue($message)

            $queueItem = PopQueueItem -Queue 'Test'

            It 'Returns an item from the queue' {
                $queueItem | Should Not BeNullOrEmpty
            }

            It 'Returns a PSObject representing the JSON text' {
                $queueItem | Should BeOfType [PSObject]
                $queueItem.Message | Should Be 'Hello world'
            }

            It 'Does not throw an error if the queue is empty' {
                $Script:queue['Test'].Count | Should Be 0
                { PopQueueItem 'Test' } | Should Not Throw
            }

            It 'Does not throw an error if the queue does not exist' {
                $Script:queue.Contains('Other') | Should Be $false
                { PopQueueItem 'Other' } | Should Not Throw
            }
        }
    }
}