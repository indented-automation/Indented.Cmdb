CmdbItem DiskPartition @{
    Get = {
        Get-WmiObject Win32_DiskPartition -ComputerName $Node.Name | ForEach-Object {
            $DiskDrive = $_.GetRelated('Win32_DiskDrive')
            $LogicalDisk = $_.GetRelated('Win32_LogicalDisk')
            $Volume = Get-WmiObject Win32_Volume -Filter "Name='$($LogicalDisk.DeviceID)\\'" -ComputerName $Node.Name
            
            [PSCustomObject]@{
                Name                  = $_.Name
                BlockSize             = $Volume.BlockSize
                Bootable              = $_.Bootable
                DeviceID              = $_.DeviceID
                PrimaryPartition      = $_.PrimaryPartition
                Size                  = $_.Size
                StartingOffset        = $_.StartingOffset
                DiskDriveDeviceID     = $DiskDrive.DeviceID
                LogicalDiskDeviceID   = $LogicalDisk.DeviceID
                FileSystem            = $LogicalDisk.FileSystem
                LogicalDiskFreeSpace  = $LogicalDisk.FreeSpace
                LogicalDiskSize       = $LogicalDisk.Size
                LogicalDiskVolumeName = $LogicalDisk.VolumeName
            }
        }
    }
}