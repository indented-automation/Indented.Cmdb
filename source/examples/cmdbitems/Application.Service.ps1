CmdbItem Application.Service @{
    Properties = @(
        'Name'
        'DisplayName'
        'Description'
        'PathName'
        'StartMode'
        'StartName'
        'State'
    )

    Get = {
        Get-WmiObject Win32_Service -ComputerName $Node.Name -Property $Item.Properties
    }
}