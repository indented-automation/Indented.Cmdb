CmdbItem Drivers.System @{
    Properties = @(
        'Name'
        'DisplayName'
        'Description'
        'ServiceType'
        'PathName'
        'Status'
        'State'
        'StartMode'
    )

    Get = {
        Get-WmiObject Win32_SystemDriver -ComputerName $Node.Name -Property $Item.Properties
    }
}