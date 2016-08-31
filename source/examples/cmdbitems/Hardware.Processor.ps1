CmdbItem Hardware.Processors @{
    Properties = @(
        'DeviceID'
        'MaxClockSpeed'
        'Description'
        'Manufacturer'
        'NumberOfCores'
        'NumberOfLogicalProcessors'
        'ProcessorID'
    )

    Get = {
        Get-WmiObject Win32_Processor -ComputerName $Node.Name -Property $Item.Properties
    }
}