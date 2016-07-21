InModuleScope Indented.Cmdb {
    Describe 'Get-CmdbData' {
        $Script:settings = [PSCustomObject]@{
            DatabaseMode = 'Memory'
        }
        $Script:data = 1

        It 'Returns the data store if the DatabaseMode is Memory' {
            Get-CmdbData | Should Be 1
        }
    
        $Script:settings.DatabaseMode = 'Folder'

        It 'Returns nothing if the DatabaseMode is not Memory' {
            Get-CmdbData | Should BeNullOrEmpty
        }
    }
}