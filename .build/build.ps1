#requires -Module Configuration

param(
    [Parameter(Position = 1)]
    [ValidateSet('Build', 'Minor', 'Major')]
    [String]$ReleaseType = 'Build',

    [Boolean]$TryLoadModule = $true
)

# Build the paths required

$moduleBase = (Get-Item $psscriptroot).Parent.FullName
$moduleName = Split-Path $moduleBase -Leaf

Write-Host "Building $moduleName"

#
# Module load test
#

if ($TryLoadModule) {
    $psHost = [PowerShell]::Create()
    $psHost.AddCommand("Import-Module").AddParameter("Name", "$moduleBase\$moduleName.psd1").Invoke()
    if ($psHost.HadErrors) {
        Write-Host "Module failed to load"
        $psHost.Streams.Error | ForEach-Object {
            Write-Host $_.Exception.Message.Trim() -ForegroundColor White
        }
        Write-Host "Aborting build!" -ForegroundColor Red
        break
    }
}

if (Test-Path "$psscriptroot\Package") {
    Remove-Item "$psscriptroot\Package" -Recurse -Force -Confirm:$false
}
$null = New-Item "$psscriptroot\Package" -ItemType Directory

#
# Generate the PSM1
#

$fileStream = New-Object System.IO.FileStream("$psscriptroot\Package\$moduleName.psm1", 'Create')
$writer = New-Object System.IO.StreamWriter($fileStream)

Write-Host "Building PSM1"

'Internal', 'Public' | ForEach-Object {
    $access = $_

    if ((Test-Path "$moduleBase\$_") -and (Test-Path "$moduleBase\$_\*")) {
        $writer.WriteLine()
        $writer.WriteLine("# $_")

        Get-ChildItem "$moduleBase\$_" -Filter *.ps1 -Recurse | ForEach-Object {
            Write-Host "  Merging $moduleName\$access\$($_.Name)" -ForegroundColor Gray
            $writer.WriteLine()

            Get-Content $_.FullName | ForEach-Object {
                $writer.WriteLine($_.TrimEnd())
            }
        }
    }
}

if (Test-Path "$moduleBase\Internal\InitializeModule.ps1") {
    Write-Host "  Adding InitializeModule call"

    $writer.WriteLine()
    $writer.WriteLine("InitializeModule")
}

$writer.Close()
$fileStream.Close()

#
# Format files
#

if (Test-Path "$moduleBase\*.Format.ps1xml") {
    Write-Host "Importing format files"

    Get-ChildItem "$moduleBase\*.Format.ps1xml" | ForEach-Object {
        Write-Host "  Adding $($_.Name)"

        Copy-Item $_.FullName "$psscriptroot\Package" -Force
    }
}

if (Test-Path "$moduleBase\$moduleName.psd1") {
    Write-Host "Updating manifest"

    #
    # Version
    #

    Update-Metadata "$moduleBase\$moduleName.psd1" -Increment $ReleaseType
    Copy-Item "$moduleBase\$moduleName.psd1" "$psscriptroot\Package" -Force

    #
    # FunctionsToExport
    #

    Update-Metadata "$psscriptroot\Package\$moduleName.psd1" -Property 'FunctionsToExport' -Value (
        Get-ChildItem "$moduleBase\Public" -File -Filter *.ps1 -Recurse | Select-Object -ExpandProperty BaseName
    )
}

#
# Other content
#

Get-ChildItem $moduleBase |
    Where-Object { $_.Name -notin '.git', '.gitignore', '.build', '.vscode', 'internal', 'public', 'tests' -and $_.Extension -notin '.psd1', '.psm1', '.ps1xml' } |
    ForEach-Object {
        Write-Host "Adding other content $($_.Name)" -ForegroundColor Gray

        Copy-Item $_.FullName "$psscriptroot\Package" -Recurse -Force
    }

Write-Host "Complete!" -ForegroundColor Green
