InModuleScope Indented.Cmdb {
    Describe 'Get-CmdbDataService' {
        $Script:dataServicePSHost = 1

        It 'Returns the PS host executing the data service' {
            Get-CmdbDataService | Should Be 1
        }
    }
}