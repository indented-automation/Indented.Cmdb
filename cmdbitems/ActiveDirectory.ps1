CmdbItem ActiveDirectory @{
    Properties = @(
        'Name'
        'Enabled'
        'ObjectGUID'
        'OperatingSystem'
        'OperatingSystemServicePack'
        'ServicePrincipalName'
        'UserAccountControl'
        'WhenCreated'
    )

    Get = {
        Import-Module ActiveDirectory

        Get-ADComputer -Identity $Node.Name -Properties $Item.Properties
    }

    Import = {
        Get-ADComputer -Filter { Enabled -eq $true -and operatingSystem -like '*Server*' } -Properties $Item.Properties
    }
}