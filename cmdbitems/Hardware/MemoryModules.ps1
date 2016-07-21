CmdbItem MemoryModules @{
    Properties = @(
        'BankLabel'
        'Capacity'
        'DeviceLocator'
        'Manufacturer'
        'PartNumber'
        'SerialNumber'
        'Speed'
    )

    Get = {
        Get-WmiObject Win32_PhysicalMemory -ComputerName $Node.Name -Property $Item.Properties
    }
}