InModuleScope Indented.Cmdb {
    Describe 'Get-CmdbNode' {
        $Script:settings = [PSCustomObject]@{
            MessageBusMode = 'Folder'
            ClientTimeout  = 5
        }

        Mock Get-CmdbItem { }
        Mock PopQueueItem {
            [PSCustomObject]@{
                Values = 1
            }
        }
        Mock PushQueueItem { }
        Mock ReadGetDataQueue { }
        Mock RemoveQueue { }
        Mock Start-Sleep { }

        $defaultParams = @{
            Name = 'somenodename'
        }

        It 'Pushes requests onto the GetData queue' {
            Get-CmdbNode @defaultParams
            Assert-MockCalled PushQueueItem -Exactly -Scope It
        }

        It 'Retrieves items from a request specific queue' {
            Get-CmdbNode @defaultParams
            Assert-MockCalled PopQueueItem -Exactly 1 -Scope It
        }

        It 'Removes the client-specific queue created by the request' {
            Get-CmdbNode @defaultParams
            Assert-MockCalled RemoveQueue -Exactly 1 -Scope It
        }

        It 'Returns the Values property from the response' {
            Get-CmdbNode @defaultParams | Should Be 1
        }

        Context 'Item handling' {
            $testParams = $defaultParams.Clone()
            $testParams.Add('Item', 'someitem')

            Mock Get-CmdbItem {
                [PSCustomObject]@{
                    Name          = $Name
                    CanonicalName = $Name
                    Path          = "TestDrive:\$Name.ps1"
                }
            }

            It 'Adds items to the request if the Item parameter is set' {
                Get-CmdbNode @testParams
                Assert-MockCalled Get-CmdbItem -Exactly 1 -Scope It
            }

            Mock Get-CmdbItem {
                throw 'SomeError'
            }

            It 'Throws a terminating error if Get-CmdbItem throws a terminating error' {
                { Get-CmdbNode @testParams } | Should Throw 'SomeError' 
            }

            Mock Get-CmdbItem {
                Write-Error 'SomeError'
            }

            It 'Throws a terminating error if Get-CmdbItem throws a non-terminating error' {
                { Get-CmdbNode @testParams } | Should Throw 'SomeError' 
            }
        }

        Context 'Timeout handling' {
            $Script:i = 0
            Mock PopQueueItem {
                $Script:i++
                if ($Script:i -ge 3) {
                    [PSCustomObject]@{
                        Values = 1
                    }
                }
            }

            It 'Calls PopQueueItem once a second until a response is received' {
                Get-CmdbNode @defaultParams
                Assert-MockCalled PopQueueItem -Exactly 3 -Scope It
            }

            Mock PopQueueItem { }

            It 'Throws a non-terminating error if the timeout period expires and there is no response' {
                try {
                    Get-CmdbNode @defaultParams -ErrorAction Stop
                } catch {
                    $errorID = $_.FullyQualifiedErrorID
                }

                $errorID | Should Be 'GetDataTimeout,Get-CmdbNode'
                Assert-MockCalled PopQueueItem -Exactly $Script:settings.ClientTimeout -Scope It
                { Get-CmdbNode @defaultParams -ErrorAction SilentlyContinue } | Should Not Throw
            }
        }

        Context 'Empty response handling' {
            Mock PopQueueItem {
                [PSCustomObject]@{
                    Values = $null
                }
            }

            It 'Writes a warning message if the response is valid but contains no data' {
                Get-CmdbNode @defaultParams -WarningVariable warning -WarningAction SilentlyContinue
                "$warning" | Should Be 'The request for somenodename was successful, but no data was available.'
            }
        }

        Context 'Memory based message bus' {
            It 'Does not attempt call data service functions when the message bus node is not set to Memory' {
                Get-CmdbNode @defaultParams
                Assert-MockCalled ReadGetDataQueue -Exactly 0 -Scope It
            }

            $Script:settings.MessageBusMode = 'Memory'

            It 'Calls functions from the data service if the message bus is held in memory' {
                Get-CmdbNode @defaultParams
                Assert-MockCalled ReadGetDataQueue -Exactly 1 -Scope It
            }

            $Script:settings.MessageBusMode = 'Folder'
        }
    }
}