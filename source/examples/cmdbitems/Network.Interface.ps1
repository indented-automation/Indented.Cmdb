CmdbItem Network.Interface @{
    Get = {
        Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled='TRUE'" -ComputerName $Node.Name | ForEach-Object {
            $NetworkAdapter = $_.GetRelated('Win32_NetworkAdapter')

            [PSCustomObject]@{
                Name                 = $NetworkAdapter.Name
                NetConnectionID      = $NetworkAdapter.NetConnectionID
                Status               = $NetworkAdapter.NetConnectionStatus
                IPAddress            = $_.IPAddress
                IPSubnet             = $_.IPSubnet
                DefaultIPGateway     = $_.DefaultIPGateway
                MacAddress           = $_.MACAddress
                DhcpEnabled          = $_.DhcpEnabled
                DHCPLeaseObtained    = $(try { [System.Management.ManagementDateTimeConverter]::ToDateTime($_.DhcpLeaseObtained) } catch { })
                DhcpLeaseExpires     = $(try { [System.Management.ManagementDateTimeConverter]::ToDateTime($_.DhcpLeaseExpires) } catch  { })
                DhcpServer           = $_.DhcpServer
                DnsServerSearchOrder = $_.DnsServerSearchOrder 
                WinsPrimaryServer    = $_.WinsPrimaryServer
                WinsSecondaryServer  = $_.WinsSecondaryServer
                Speed                = $NetworkAdapter.Speed
                Manufacturer         = $NetworkAdapter.Manufacturer
                ProductName          = $NetworkAdapter.ProductName
            }
        }
    }
}