CmdbItem System @{
    Properties = @(
        'Manufacturer'
        'Model'
        'NumberOfLogicalProcessors'
        'SystemType'
        'TotalPhysicalMemory'
    )

    Get = {
        Get-WmiObject  Win32_ComputerSystem -ComputerName $Node.Name -Property $Item.Properties
    }
}