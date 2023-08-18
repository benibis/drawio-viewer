param(
    [string]$path1,
    [string]$path2
)

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$outputFilePath = Join-Path (Get-Item $path2).Parent.FullName ("$timestamp-drawio-compare.txt")

$files1 = Get-ChildItem -Path $path1 -Filter "*.drawio" -File -Recurse
$files2 = Get-ChildItem -Path $path2 -Filter "*.drawio" -File -Recurse

$outputLines = @()

foreach ($file1 in $files1) {
    $matchingFile = $files2 | Where-Object { $_.Name -eq $file1.Name -and $_.FullName -replace [regex]::Escape($path2), $path1 }

    if ($matchingFile) {
        $xml1 = Get-Content -Path $file1.FullName -Raw
        $xml2 = Get-Content -Path $matchingFile.FullName -Raw

        if ($xml1 -ne $xml2) {
            $outputLines += ("Differences found in $($file1.FullName) and $($matchingFile.FullName):")
            
            $diff = Compare-Object $xml1.Split("`n") $xml2.Split("`n")
            foreach ($line in $diff) {
                if ($line.SideIndicator -eq '<=') {
                    $outputLines += "removed $($line.InputObject)"
                } elseif ($line.SideIndicator -eq '=>') {
                    $outputLines += "added $($line.InputObject)"
                }
            }
        }
    } else {
        $outputLines += ("File $($file1.FullName) does not exist in the second directory.")
    }
}

foreach ($file2 in $files2) {
    $matchingFile = $files1 | Where-Object { $_.Name -eq $file2.Name -and $_.FullName -replace [regex]::Escape($path1), $path2 }

    if (!$matchingFile) {
        $outputLines += ("File $($file2.FullName) does not exist in the first directory.")
    }
}

if ($outputLines.Count -gt 0) {
    $outputLines | Set-Content -Path $outputFilePath
    Write-Host "Differences written to $($outputFilePath)"
} else {
    Write-Host "No differences found."
}
