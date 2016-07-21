CmdbItem VirtualMachineHost @{
    ImportPSSnapIn = 'VMWare.VimAutomation.Core'
    
    SCVMMServers = @()
    vSphereServers = @()

    CopyToNode = @(
        'FQDN'
        'Type'
        'VMManagementServer'
    )

    Get = {
        if ($Node.Type -eq 'HyperVVirtualMachineHost') {
            & $Item.SCVMM $Node
        } elseif ($Node.Type -eq 'VMWareVirtualMachineHost') {
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
                    Get-SCVMHost @params | ForEach-Object {
                        [PSCustomObject]@{
                            Name               = $_.Name
                            ComputerName       = $_.Name -replace '\..+$'
                            FQDN               = $_.Name
                            ConnectionState    = $_.CommunicationStateString
                            Manufacturer       = $null
                            MemoryGB           = $_.TotalMemory / 1GB
                            Model              = $null
                            NumberOfCores      = $_.CoresPerCPU * $_.PhysicalCPUCount
                            NumberOfProcessors = $_.PhysicalCPUCount
                            OperatingSystem    = $_.OperatingSystem.Name
                            Type               = 'HyperVVirtualMachineHost'
                            VMCluster          = $_.HostCluster.Name
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
                    Get-VMHost @params | ForEach-Object {
                        $VMCluster = $null
                        $VMCluster = VMware.VimAutomation.Core\Get-Cluster -VMHost $_.Name -ErrorAction SilentlyContinue
            
                        [PSCustomObject]@{
                            Name               = $_.Name
                            ComputerName       = $_.Name -replace '\..+$'
                            FQDN               = $_.Name
                            ConnectionState    = $_.ConnectionState
                            Manufacturer       = $_.Manufacturer
                            MemoryGB           = $_.TotalMemoryDB
                            Model              = $_.Model
                            NumberOfCores      = $_.ExtensionData.Hardware.CpuInfo.NumCpuCores
                            NumberOfProcessors = $_.ExtensionData.Hardware.CpuInfo.NumCpuPackages
                            OperatingSystem    = 'VMware ESX {0} ({1})' -f $_.Version, $_.Build
                            Type               = 'VMWareVirtualMachineHost'
                            VMCluster          = $VMCluster
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