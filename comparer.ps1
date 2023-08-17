param(
    [string]$path1,
    [string]$path2
)

function Get-DrawioFileContent {
    param(
        [string]$filePath
    )
    
    $content = Get-Content -Path $filePath -Raw
    $xml = [xml]$content
    return $xml
}

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$outputFilePath = Join-Path $path2 ("$timestamp-drawio-compare.txt")

$files1 = Get-ChildItem -Path $path1 -Filter "*.drawio" -File -Recurse
$files2 = Get-ChildItem -Path $path2 -Filter "*.drawio" -File -Recurse

$outputLines = @()

foreach ($file1 in $files1) {
    $matchingFile = $files2 | Where-Object { $_.Name -eq $file1.Name -and $_.FullName -replace [regex]::Escape($path2), $path1 }
    
    if ($matchingFile) {
        $xml1 = Get-DrawioFileContent -filePath $file1.FullName
        $xml2 = Get-DrawioFileContent -filePath $matchingFile.FullName
        
        $xmlDiff = Compare-Object $xml1.InnerXml $xml2.InnerXml
        
        $differences = @()
        
        foreach ($diffItem in $xmlDiff) {
            if ($diffItem.SideIndicator -eq '=>') {
                $addedTag = $xml2.SelectSingleNode($diffItem.InputObject)
                $differences += "added $($addedTag.Name) $($addedTag.Attributes['value'].Value)"
            } elseif ($diffItem.SideIndicator -eq '<=') {
                $removedTag = $xml1.SelectSingleNode($diffItem.InputObject)
                $differences += "removed $($removedTag.Name) $($removedTag.Attributes['value'].Value)"
            } else {
                $tag = $xml1.SelectSingleNode($diffItem.InputObject)
                $value1 = $tag.Attributes['value'].Value
                $value2 = $xml2.SelectSingleNode($diffItem.InputObject).Attributes['value'].Value
                if ($value1 -ne $value2) {
                    $differences += "$($tag.Name): $value1 -> $value2"
                }
            }
        }
        
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
        $xml2 = Get-DrawioFileContent -filePath $file2.FullName
        
        $addedTags = $xml2.SelectNodes("//*[not(ancestor::*)]")
        
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
