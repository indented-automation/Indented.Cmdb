CmdbItem HBA @{
    Properties = @(
        'Active'
        'DriverName'
        'FirmwareVersion'
        'Manufacturer'
        'Model'
        'ModelDescription'
        @{Name = 'NodeWWN'; Expression = { ($_.NodeWWN | ForEach-Object { '{0:X2}' -f $_ }) -join '' }}
        'NumberOfPorts'
        'SerialNumber'
    )

    Get = {
        Get-WmiObject MSFC_FCAdapterHBAAttributes -Namespace root\WMI -ComputerName $Node.Name
    }
}