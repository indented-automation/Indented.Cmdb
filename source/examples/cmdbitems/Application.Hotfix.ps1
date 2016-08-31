CmdbItem Application.Hotfix @{
    Properties = @(
        'HotFixID'
        'Description'
        'Caption'
        'InstalledBy'
        'InstalledOn'
    )

    Get = {
        Get-WmiObject Win32_QuickFixEngineering -ComputerName $Node.Name -Property $Item.Properties |
            Where-Object { $_.HotfixID -ne 'File 1' }
    }
}