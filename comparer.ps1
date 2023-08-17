param(
    [string]$path1,
    [string]$path2
)

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$outputFilePath = Join-Path $path2 ("$timestamp-drawio-compare.txt")

function Compare-DrawioFiles {
    param(
        [string]$filePath1,
        [string]$filePath2
    )
    
    $xml1 = New-Object System.Xml.XmlDocument
    $xml2 = New-Object System.Xml.XmlDocument

    $xml1.Load($filePath1)
    $xml2.Load($filePath2)

    $differences = @()

    $xml1.SelectNodes("//mxfile/*") | ForEach-Object {
        $tag = $_
        $name = $tag.Name
        $value1 = $tag.Attributes["value"].Value
        $value2 = $xml2.SelectSingleNode("//mxfile/$name").Attributes["value"].Value

        if ($value1 -ne $value2) {
            $differences += "$name: $value1 -> $value2"
        }
    }

    return $differences
}

$files1 = Get-ChildItem -Path $path1 -Filter "*.drawio" -File -Recurse
$files2 = Get-ChildItem -Path $path2 -Filter "*.drawio" -File -Recurse

$outputLines = @()

foreach ($file1 in $files1) {
    $matchingFile = $files2 | Where-Object { $_.Name -eq $file1.Name -and $_.FullName -replace [regex]::Escape($path2), $path1 }
    
    if ($matchingFile) {
        $differences = Compare-DrawioFiles -filePath1 $file1.FullName -filePath2 $matchingFile.FullName

        if ($differences.Count -gt 0) {
            $outputLines += ("Differences found in $($file1.FullName) and $($matchingFile.FullName):" + $differences)
        }
    } else {
        $outputLines += ("File $($file1.FullName) does not exist in the second directory.")
    }
}

foreach ($file2 in $files2) {
    $matchingFile = $files1 | Where-Object { $_.Name -eq $file2.Name -and $_.FullName -replace [regex]::Escape($path1), $path2 }
    
    if (!$matchingFile) {
        $xml2 = New-Object System.Xml.XmlDocument
        $xml2.Load($file2.FullName)

        $addedTags = $xml2.SelectNodes("//mxfile/*")

        foreach ($tag in $addedTags) {
            $outputLines += ("added $($tag.Name) $($tag.Attributes['value'].Value)")
        }
    }
}

if ($outputLines.Count -gt 0) {
    $outputLines | Set-Content -Path $outputFilePath
    Write-Host "Differences written to $($outputFilePath)"
} else {
    Write-Host "No differences found."
}
