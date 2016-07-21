CmdbItem BIOS @{
    Properties = @(
        'Name'
        'Version'
        'SerialNumber'
        'ReleaseDate'
    )

    Get = {
        Get-WmiObject Win32_BIOS -ComputerName $Node.Name -Property $Item.Properties
    }
}