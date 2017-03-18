CmdbItem Application.ScheduledTask @{
    Get = {
        Import-Module ScheduledTasks

        $cimSessionOptions = New-CimSessionOption -Protocol Dcom
        $cimSession = New-CimSession -ComputerName $Node.Name -SessionOption $cimSessionOptions

        Get-ScheduledTask -CimSession $cimSession |
            Where-Object {
                $_.Author -notmatch 'Microsoft( Corporation\.?)?' -and 
                $_.TaskPath -notlike '\Microsoft\Windows*' -and 
                $_.TaskName -ne 'SvcRestartTask'
            } |
            ForEach-Object {
                [PSCustomObject]@{
                    TaskName         = $_.TaskName
                    State            = $_.State
                    Enabled          = $_.Settings.Enabled
                    TaskPath         = $_.TaskPath
                    Author           = $_.Author
                    Description      = $_.Description
                    RunAs            = $_.Principal.UserId
                    RunLevel         = $_.Principal.RunLevel
                    RunLogonType     = $_.Principal.LogonType
                    Execute          = $_.Actions.Execute
                    Arguments        = $_.Actions.Arguments
                    WorkingDirectory = $_.Actions.WorkingDirectory
                }
            }

        $cimSession = $null
        $cimSessionOptions = $null
    }
}