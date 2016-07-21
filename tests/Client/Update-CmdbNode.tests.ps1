InModuleScope Indented.Cmdb {
    Describe 'Update-CmdbNode' {
        $Script:settings = [PSCustomObject]@{
            MessageBusMode = 'Folder'
        }
        $Script:requestID = $null

        Mock Get-CmdbItem {
            [PSCustomObject]@{
                Name          = $Name
                CanonicalName = $Name
                Path          = "TestDrive:\$Name.ps1"
            }
        }
        Mock GetCmdbItemObject {
            [PSCustomObject]@{
                Name        = $CmdbItem.Name
                SupportsGet = $true
            }
        }
        Mock PushQueueItem {
            $Script:requestID = $Message.ID.ToString()
        }
        Mock ReadUpdateQueue {
            $Script:updateWorkQueue = New-Object System.Collections.Generic.Dictionary"[String,PSObject]"
            $null = $Script:updateWorkQueue.Add(
                $Script:requestID,
                [PSCustomObject]@{
                    Host = [PSCustomObject]@{
                        InvocationStateInfo = [PSCustomObject]@{
                            State = 'Complete'
                        }
                    }
                }
            )
        }
        Mock Get-CmdbWorkQueue {
            [PSCustomObject]@{
                Update = $Script:updateWorkQueue 
            }
        }
        Mock PublishUpdateItem { }
        Mock ReadSetDataQueue { }
        Mock Start-Sleep { }

        $defaultParams = @{
            Name = 'somenodename'
            Item = 'item1'
        }

        It 'Returns nothing' {
            Update-CmdbNode @defaultParams | Should BeNullOrEmpty
        }

        It 'Gets each item using Get-CmdbItem' {
            Update-CmdbNode @defaultParams
            Assert-MockCalled Get-CmdbItem -Exactly 1 -Scope It
        }

        It 'Executes each instance of CmdbItem' {
            Update-CmdbNode @defaultParams
            Assert-MockCalled GetCmdbItemObject -Exactly 1 -Scope It
        }

        It 'Pushes requests where the item supports updating' {
            Update-CmdbNode @defaultParams
            Assert-MockCalled PushQueueItem -Exactly 1 -Scope It
        }

        Context 'Update all items' {
            Mock Get-CmdbItem {
                1..5 | ForEach-Object {
                    [PSCustomObject]@{
                        Name          = $_
                        CanonicalName = $_
                        Path          = "TestDrive:\$_.ps1"
                    }
                }
            }

            It 'Updates all available items when the Item parameter is not set' {
                Update-CmdbNode -Name 'somenodename'
                Assert-MockCalled Get-CmdbItem -Exactly 1 -Scope It
                Assert-MockCalled GetCmdbItemObject -Exactly 5 -Scope It
            }
        }

        Context 'Get-CmdbItem error handling' {
            Mock Get-CmdbItem {
                throw 'SomeError'
            }

            It 'Throws a non-terminating error if Get-CmdbItem throws an error' {
                { Update-CmdbNode @defaultParams -ErrorAction SilentlyContinue } | Should Not Throw
                { Update-CmdbNode @defaultParams -ErrorAction Stop } | Should Throw 'SomeError'
                Assert-MockCalled GetCmdbItemObject -Exactly 0 -Scope It
            }
        }

        Context 'Update support' {
            Mock GetCmdbItemObject {
                [PSCustomObject]@{
                    Name        = $CmdbItem.Name
                    SupportsGet = $false
                }
            }

            It 'Does not push requests onto the queue if the item does not support get' {
                Update-CmdbNode @defaultParams
                Assert-MockCalled GetCmdbItemObject -Exactly 1 -Scope It
                Assert-MockCalled PushQueueItem -Exactly 0 -Scope It
            }
        }

        Context 'Memory based message bus' {
            It 'Does not attempt call poller or data service functions when the message bus node is not set to Memory' {
                Update-CmdbNode @defaultParams
                Assert-MockCalled ReadUpdateQueue -Exactly 0 -Scope It
                Assert-MockCalled Get-CmdbWorkQueue -Exactly 0 -Scope It
                Assert-MockCalled PublishUpdateItem -Exactly 0 -Scope It
                Assert-MockCalled ReadSetDataQueue -Exactly 0 -Scope It
            }

            $Script:settings.MessageBusMode = 'Memory'

            It 'Calls ReadUpdateQueue to force act on the request' {
                Update-CmdbNode @defaultParams
                Assert-MockCalled ReadUpdateQueue -Exactly 1 -Scope It
            }

            It 'Gets the update work queue' {
                Update-CmdbNode @defaultParams
                Assert-MockCalled Get-CmdbWorkQueue -Exactly 1 -Scope It
            }

            It 'Does not wait if the job has completed' {
                Update-CmdbNode @defaultParams
                Assert-MockCalled Start-Sleep -Exactly 0 -Scope It
            }

            It 'Calls PublishUpdateItem to move the completed work item to the SetData queue' {
                Update-CmdbNode @defaultParams
                Assert-MockCalled PublishUpdateItem -Exactly 1 -Scope It
            }

            It 'Calls ReadSetDataQueue to add item information to the data service' {
                Update-CmdbNode @defaultParams
                Assert-MockCalled ReadSetDataQueue -Exactly 1 -Scope It
            }

            Mock ReadUpdateQueue {
                $null = $Script:updateWorkQueue.Add(
                    $Script:requestID,
                    [PSCustomObject]@{
                        Host = [PSCustomObject]@{
                            InvocationStateInfo = [PSCustomObject]@{
                                State = 'NotStarted'
                            }
                        }
                    }
                )
            }
            $Script:i = 0
            Mock Start-Sleep {
                $Script:i++
                if ($Script:i -eq 1) {
                    $Script:updateWorkQueue[$Script:requestID].Host.InvocationStateInfo.State = 'Running'
                }
                if ($Script:i -ge 10) {
                    $Script:updateWorkQueue[$Script:requestID].Host.InvocationStateInfo.State = 'Complete'
                }
            }

            It 'Waits for long-running updates to complete' {
                Update-CmdbNode @defaultParams
                Assert-MockCalled Start-Sleep -Exactly 10 -Scope It
            }

            $Script:settings.MessageBusMode = 'Folder'
        }
    }
}