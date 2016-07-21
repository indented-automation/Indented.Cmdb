CmdbItem ComputerSystemProduct @{
    Properties = @(
        'UUID'
        'Vendor'
        'Version'
    )

    Get = {
        Get-WmiObject Win32_ComputerSystemProduct -ComputerName $Node.Name -Property $Item.Properties
    }
}