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
    return $xml.OuterXml
}

$files1 = Get-ChildItem -Path $path1 -Filter "*.drawio" -File -Recurse
$files2 = Get-ChildItem -Path $path2 -Filter "*.drawio" -File -Recurse

foreach ($file1 in $files1) {
    $matchingFile = $files2 | Where-Object { $_.Name -eq $file1.Name -and $_.FullName -replace [regex]::Escape($path2), $path1 }
    
    if ($matchingFile) {
        $content1 = Get-DrawioFileContent -filePath $file1.FullName
        $content2 = Get-DrawioFileContent -filePath $matchingFile.FullName
        
        if ($content1 -ne $content2) {
            Write-Host "Difference found in $($file1.FullName) and $($matchingFile.FullName)"
        }
    } else {
        Write-Host "File $($file1.FullName) does not exist in the second directory."
    }
}

foreach ($file2 in $files2) {
    $matchingFile = $files1 | Where-Object { $_.Name -eq $file2.Name -and $_.FullName -replace [regex]::Escape($path1), $path2 }
    
    if (!$matchingFile) {
        Write-Host "File $($file2.FullName) does not exist in the first directory."
    }
}
