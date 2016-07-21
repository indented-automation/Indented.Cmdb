InModuleScope Indented.Cmdb {
    Describe 'Start-CmdbDataService' {
        Mock NewPSHost {
            $psHost = [PSCustomObject]@{
                Commands            = New-Object System.Management.Automation.PSCommand 
                RunspacePool        = $null
                InvocationStateInfo = [PSCustomObject]@{
                    State = 'NotStarted'
                }
                Streams             = [PSCustomObject]@{
                    Error       = New-Object System.Management.Automation.PSDataCollection[System.Management.Automation.ErrorRecord]
                    Information = New-Object System.Management.Automation.PSDataCollection[System.Management.Automation.InformationRecord] 
                    Progress    = New-Object System.Management.Automation.PSDataCollection[System.Management.Automation.ProgressRecord] 
                    Verbose     = New-Object System.Management.Automation.PSDataCollection[System.Management.Automation.VerboseRecord]
                    Warning     = New-Object System.Management.Automation.PSDataCollection[System.Management.Automation.WarningRecord]
                }
            }
        
            # Command construction wiring
                    
            [System.Management.Automation.PSCommand].GetMethods().Where( { $_.Name -clike 'Add*' } ).Name | Select-Object -Unique | ForEach-Object {
                Add-Member $_ -MemberType ScriptMethod -InputObject $psHost -Value ([ScriptBlock]::Create('
                    if ($args) {{
                        $null = $this.Commands.{0}($args)
                    }} else {{
                        $null = $this.Commands.{0}()
                    }}

                    return $this
                ' -f $_))
            }
            $psHost | Add-Member 'AddParameters' -MemberType ScriptMethod -Value {
                if ($args[0] -is [Hashtable]) {
                    $args[0].Keys | ForEach-Object {
                        $null = $this.Commands.AddParameter($_, $args[0][$_])
                    }
                }

                return $this
            }

            # Invocation

            $psHost | Add-Member BeginInvoke -MemberType ScriptMethod -Value {
                $this.InvocationStateInfo.State = 'Running'

                return [PSCustomObject]@{
                    CompletedSynchronously = $false 
                    IsCompleted            = $false
                    AsyncState             = $null
                    AsyncWaitHandle        = $null
                }
            }
            $psHost | Add-Member Invoke -MemberType ScriptMethod -Value {
                $this.InvocationStateInfo.State = 'Completed'
            }
            $psHost | Add-Member Stop -MemberType ScriptMethod -Value {
                $this.InvocationStateInfo.State = 'Stopped'
            }

            # Streams

            $psHost.Streams | Add-Member ClearStreams -MemberType ScriptMethod -Value {
                'Error', 'Information', 'Progress', 'Warning', 'Verbose' | ForEach-Object {
                    $this.$_.Clear()
                }
            }

            return $psHost
        }
        Mock ReadGetDataQueue { }
        Mock ReadSetDataQueue { }
        Mock Start-Sleep { }

        $Script:settings = [PSCustomObject]@{
            MessageBusMode = 'Memory'
            DatabaseMode   = 'Folder'
        }

        It 'Throws a terminating error if the message bus mode is Memory' {
            try {
                Start-CmdbDataService -Foreground
            } catch {
                $errorID = $_.FullyQualifiedErrorID
            }

            $errorID | Should Be 'InvalidMessageBus,Start-CmdbDataService'
        }

        $Script:settings = [PSCustomObject]@{
            MessageBusMode = 'Folder'
            DatabaseMode   = 'Memory'
        }

        It 'Throws a terminating error if the database mode is Memory' {
            try {
                Start-CmdbDataService -Foreground
            } catch {
                $errorID = $_.FullyQualifiedErrorID
            }

            $errorID | Should Be 'InvalidDatabaseMode,Start-CmdbDataService'
        }

        $Script:settings = [PSCustomObject]@{
            MessageBusMode = 'Folder'
            MessageBusURI  = 'TestDrive:\MessageBus'
            DatabaseMode   = 'Folder'
            DatabaseURI    = 'TestDrive:\Data'
        }
    }
}