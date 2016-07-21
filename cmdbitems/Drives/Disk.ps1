CmdbItem Disk @{
    Get = {
        if ($Node.OperatingSystem) {
            Invoke-Command -ComputerName $Node.Name -ScriptBlock {
                Get-Disk
            }
        }
    }
}