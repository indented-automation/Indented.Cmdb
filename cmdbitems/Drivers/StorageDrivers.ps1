CmdbItem StorageDrivers @{
	Get = {
        $systemDirectory = Get-WmiObject Win32_OperatingSystem -ComputerName $Node.Name -Property 'SystemDirectory' |
            Select-Object -ExpandProperty SystemDirectory
        if (-not $?) {
            $systemDirectory = "C:\Windows"
        }
        $driverDirectory = "$SystemDirectory\drivers\"
        # Escape \, reserved character in WMI filters.
        $dataFilePath = $driverDirectory -replace '\\', '\\'

        # CIM_DataFile
        'storport.sys', 'msdsm.sys', 'mpio.sys' | ForEach-Object {
            Get-WmiObject CIM_DataFile -Filter "Name='$DataFilePath$_'" -ComputerName $Node.Name |
                Select-Object @{n='Name';e={ $_.FileName }}, @{n='Version';e={ [Version]$_.Version }}, @{n='PathName';e={ $_.Name }}
        }
    }
}