InModuleScope Indented.Cmdb {
    Describe 'OpenMessageBus' {
        Context 'Folder queue' {
            $Script:settings = [PSCustomObject]@{
                MessageBusMode = 'Folder'
                MessageBusURI  = 'TestDrive:\MessageBus'
            }

            if (Test-Path 'TestDrive:\MessageBus') {
                Remove-Item 'TestDrive:\MessageBus' -Recurse -Confirm:$false
            }
            
            OpenMessageBus

            It 'Creates a root folder to host the message bus content' {
                Test-Path 'TestDrive:\MessageBus' | Should Be $true
            }

            It 'Creates folders for each of Update, Import, GetData and SetData' {
                Test-Path 'TestDrive:\MessageBus\Update' | Should Be $true
                Test-Path 'TestDrive:\MessageBus\Import' | Should Be $true
                Test-Path 'TestDrive:\MessageBus\GetData' | Should Be $true
                Test-Path 'TestDrive:\MessageBus\SetData' | Should Be $true
            }
        }

        Context 'Memory queue' {
            $Script:settings = [PSCustomObject]@{
                MessageBusMode = 'Memory'
            }

            OpenMessageBus

            It 'Creates a script level variable called queue as a Hashtable' {
                $Script:queue | Should BeOfType [Hashtable]
            }

            It 'Creates instances of System.Collections.Generic.Queue for each queue' {
                $Script:queue.Values | ForEach-Object {
                    ,$_ | Should BeOfType [System.Collections.Generic.Queue[String]]
                }
            }

            It 'Creates a queue for each of Update, Import, GetData and SetData' {
                $Script:queue.Contains('Update') | Should Be $true
                $Script:queue.Contains('Import') | Should Be $true
                $Script:queue.Contains('GetData') | Should Be $true
                $Script:queue.Contains('SetData') | Should Be $true
            }
        }


        Context 'RabbitMQ' {

        }        
    }
}