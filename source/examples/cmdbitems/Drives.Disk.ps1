CmdbItem Drives.Disk @{
    Properties = @(
        'DeviceID'
        'Partitions'
        'BytesPerSector'
        'InterfaceType'
        'SectorsPerTrack'
        'Size'
        'TotalCylinders'
        'TotalHeads'
        'TotalSectors'
        'TotalTracks'
        'TracksPerCylinder'
        'Model'
        'FirmwareRevision'
        'Name'
        'PNPDeviceID'
        'SerialNumber'
        'Signature'
        'Status'
    )

    Get = {
        Get-WmiObject Win32_DiskDrive -ComputerName $Node.Name -Property $Item.Properties
    }
}