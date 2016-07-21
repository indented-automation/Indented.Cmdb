InModuleScope Indented.Cmdb {
    Describe 'PushQueueItem' {
        $message = [PSCustomObject]@{
            ID      = 'MessageID'
            Message = 'Hello world'
        }

        Context 'Folder queue' {
            $Script:settings = [PSCustomObject]@{
                MessageBusMode = 'Folder'
                MessageBusURI  = 'TestDrive:\MessageBus'
                JsonDepth      = 10
            }

            $null = New-Item 'TestDrive:\MessageBus\Test' -ItemType Directory

            $nothing = PushQueueItem -Queue 'Test' -Message $message

            It 'Adds an item to the queue and returns nothing' {
                $nothing | Should BeNullOrEmpty
            }

            It 'Creates a file holding the json data using the ID field in the message' {
                Test-Path 'TestDrive:\MessageBus\Test\MessageID.json' | Should Be $true
                'TestDrive:\MessageBus\Test\MessageID.json' | Should Contain ''
            }

            It 'Does not throw an error if the queue does not exist' {
                Test-Path 'TestDrive:\MessageBus\Other' | Should Be $false
                { PushQueueItem -Queue 'Other' -Message $message } | Should Not Throw
            }
        }

        Context 'Memory queue' {
            $Script:settings = [PSCustomObject]@{
                MessageBusMode = 'Memory'
                JsonDepth      = 10
            }

            $Script:queue = @{}
            $Script:queue.Add('Test', (New-Object System.Collections.Generic.Queue[String]))

            $nothing = PushQueueItem -Queue 'Test' -Message $message

            It 'Adds an item to the queue and returns nothing' {
                $nothing | Should BeNullOrEmpty
            }

            It 'Creates an entry in the queue as a json formatted string' {
                $Script:queue['Test'][0] | Should Not BeNullOrEmpty
                $Script:queue['Test'][0] | Should Match 'Hello world'
            }

            It 'Does not throw an error if the queue does not exist' {
	            $Script:queue.Contains('Other') | Should Be $false
                { PushQueueItem -Queue 'Other' -Message $message } | Should Not Throw
            }
        }

        Context 'RabbitMQ' {

        }
    }
}