CmdbItem VirtualMachine @{
    ImportPSSnapIn = 'VMWare.VimAutomation.Core'

    SCVMMServers = @()
    vSphereServers = @()

    CopyToNode = @(
        'FQDN'
        'Type'
        'VMManagementServer'
    )

    Get = {
        if ($Node.Type -eq 'HyperVVirtualMachine') {
            & $Item.SCVMM $Node
        } elseif ($Node.Type -eq 'VMWareVirtualMachine') {
            & $Item.vSphere $Node
        }
    }

    Import = {
        # Allows SCVMM to overwrite vSphere 
        & $Item.vSphere
        & $Item.SCVMM
    }
    ImportMatch = 'ComputerName'

    SCVMM = {
        param(
            $Node
        )

        $managementServers = $Item.SCVMMServers
        
        $params = @{}
        if ($Node) {
            $params.Add('Name', $Node.FQDN)
            if ($Node.VMManagementServer) {
                $managementServers = $Node.VMManagementServer
            }
        }

        $managementServers | ForEach-Object {
            Invoke-Command -ComputerName $_ -ArgumentList $params -ScriptBlock {
                param( [Hashtable]$params )

                Import-Module virtualmachinemanager

                if (Get-SCVMMServer $env:COMPUTERNAME) {
                    Get-SCVirtualMachine @params | ForEach-Object {
                        [PSCustomObject]@{
                            Name               = $_.Name
                            ComputerName       = $_.ComputerName -replace '\..+$'
                            FQDN               = $_.ComputerName
                            PowerState         = $_.VirtualMachineState.ToString()
                            OperatingSystem    = $_.OperatingSystem.Name
                            Type               = 'HyperVVirtualMachine'
                            VLanId             = $_.VirtualNetworkAdapters.VLanID | Where-Object { $_ -ne 0 }
                            VMCluster          = $_.VMHost.HostCluster.Name
                            VMHost             = $_.VMHost.Name
                            VMManagementServer = $env:COMPUTERNAME
                        }
                    }
                }
            }
        }
    }

    vSphere = {
        param(
            $Node
        )

        if (Get-PSSnapIn VMWare.VimAutomation.Core -ErrorAction SilentlyContinue) {
            $managementServers = $Item.vSphereServers

            $params = @{}
            if ($Node) {
                $params.Add('Name', $Node.FQDN)
                if ($Node.VMManagementServer) {
                    $managementServers = $Node.VMManagementServer
                }
            }

            $managementServers | ForEach-Object {
                $managementServer = $_

                $server = Connect-VIServer $managementServer -Force -WarningAction SilentlyContinue

                if ($Global:DefaultVIServer) {
                    VMWare.VimAutomation.Core\Get-VM @params | Where-Object { $_.PowerState -eq 'PoweredOn' } | ForEach-Object {
                        $VMGuest = $_ | Get-VMGuest -ErrorAction SilentlyContinue
            
                        [PSCustomObject]@{
                            Name               = $_.Name
                            ComputerName       = $VMGuest.HostName -replace '\..+$'
                            FQDN               = $VMGuest.HostName
                            PowerState         = $_.PowerState.ToString()
                            OperatingSystem    = $VMGuest.OSFullName
                            Type               = 'VMWareVirtualMachine'
                            VLanId             = $_ | Get-VirtualPortGroup | Select-Object -ExpandProperty VLanId | Where-Object { $_ -ne 0 }
                            VMCluster          = (VMWare.VimAutomation.Core\Get-Cluster -VMHost $_.VMHost).Name
                            VMHost             = $_.VMHost.Name
                            VMManagementServer = $managementServer
                        }
                    }
                }
                if ($server -and $server.IsConnected) {
                    Disconnect-VIServer $server -Force -Confirm:$false
                }
            }
        }
    }
}