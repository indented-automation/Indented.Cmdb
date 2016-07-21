InModuleScope Indented.Cmdb {
    Describe 'Import-CmdbNode' {
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
                Name           = $CmdbItem.Name
                SupportsImport = $true
            }
        }
        Mock PushQueueItem {
            $Script:requestID = $Message.ID.ToString()
        }
        Mock ReadImportQueue {
            $Script:importWorkQueue = New-Object System.Collections.Generic.Dictionary"[String,PSObject]"
            $null = $Script:importWorkQueue.Add(
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
                Import = $Script:importWorkQueue 
            }
        }
        Mock PublishImportItem { }
        Mock ReadSetDataQueue { }
        Mock Start-Sleep { }

        $defaultParams = @{
            Item = 'item1'
        }

        It 'Returns nothing' {
            Import-CmdbNode @defaultParams | Should BeNullOrEmpty
        }

        It 'Gets each item using Get-CmdbItem' {
            Import-CmdbNode @defaultParams
            Assert-MockCalled Get-CmdbItem -Exactly 1 -Scope It
        }

        It 'Executes each instance of CmdbItem' {
            Import-CmdbNode @defaultParams
            Assert-MockCalled GetCmdbItemObject -Exactly 1 -Scope It
        }

        It 'Pushes requests where the item supports importing' {
            Import-CmdbNode @defaultParams
            Assert-MockCalled PushQueueItem -Exactly 1 -Scope It
        }

        Context 'Get-CmdbItem error handling' {
            Mock Get-CmdbItem {
                throw 'SomeError'
            }

            It 'Throws a non-terminating error if Get-CmdbItem throws an error' {
                { Import-CmdbNode @defaultParams -ErrorAction SilentlyContinue } | Should Not Throw
                { Import-CmdbNode @defaultParams -ErrorAction Stop } | Should Throw 'SomeError'
                Assert-MockCalled GetCmdbItemObject -Exactly 0 -Scope It
            }
        }

        Context 'Import support' {
            Mock GetCmdbItemObject {
                [PSCustomObject]@{
                    Name           = $CmdbItem.Name
                    SupportsImport = $false
                }
            }

            It 'Does not push requests onto the queue if the item does not support import' {
                Import-CmdbNode @defaultParams
                Assert-MockCalled GetCmdbItemObject -Exactly 1 -Scope It
                Assert-MockCalled PushQueueItem -Exactly 0 -Scope It
            }
        }

        Context 'Memory based message bus' {
            It 'Does not attempt call poller or data service functions when the message bus node is not set to Memory' {
                Import-CmdbNode @defaultParams
                Assert-MockCalled ReadImportQueue -Exactly 0 -Scope It
                Assert-MockCalled Get-CmdbWorkQueue -Exactly 0 -Scope It
                Assert-MockCalled PublishImportItem -Exactly 0 -Scope It
                Assert-MockCalled ReadSetDataQueue -Exactly 0 -Scope It
            }

            $Script:settings.MessageBusMode = 'Memory'

            It 'Calls ReadImportQueue to force act on the request' {
                Import-CmdbNode @defaultParams
                Assert-MockCalled ReadImportQueue -Exactly 1 -Scope It
            }

            It 'Gets the import work queue' {
                Import-CmdbNode @defaultParams
                Assert-MockCalled Get-CmdbWorkQueue -Exactly 1 -Scope It
            }

            It 'Does not wait if the job has completed' {
                Import-CmdbNode @defaultParams
                Assert-MockCalled Start-Sleep -Exactly 0 -Scope It
            }

            It 'Calls PublishImportItem to move the completed work item to the SetData queue' {
                Import-CmdbNode @defaultParams
                Assert-MockCalled PublishImportItem -Exactly 1 -Scope It
            }

            It 'Calls ReadSetDataQueue to add item information to the data service' {
                Import-CmdbNode @defaultParams
                Assert-MockCalled ReadSetDataQueue -Exactly 1 -Scope It
            }

            Mock ReadImportQueue {
                $null = $Script:importWorkQueue.Add(
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
                    $Script:importWorkQueue[$Script:requestID].Host.InvocationStateInfo.State = 'Running'
                }
                if ($Script:i -ge 10) {
                    $Script:importWorkQueue[$Script:requestID].Host.InvocationStateInfo.State = 'Complete'
                }
            }

            It 'Waits for long-running import items to complete' {
                Import-CmdbNode @defaultParams
                Assert-MockCalled Start-Sleep -Exactly 10 -Scope It
            }

            $Script:settings.MessageBusMode = 'Folder'
        }
    }
}