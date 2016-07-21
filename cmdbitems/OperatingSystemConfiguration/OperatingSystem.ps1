CmdbItem OperatingSystem @{
    Properties = @(
        'Caption'
        'InstallDate'
        'BootDevice'
        'BuildNumber'
        'OSArchitecture'
        'SystemDrive'
        'SystemDirectory'
        'WindowsDirectory'
    )

    Get = {
        Get-WmiObject Win32_OperatingSystem -ComputerName $Node.Name -Property $Item.Properties
    }
}