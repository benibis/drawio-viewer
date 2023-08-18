param(
    [string]$path1,
    [string]$path2,
    [string]$xsltFilePath
)

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$outputFilePath = Join-Path $path2 ("$timestamp-drawio-compare.txt")

function Transform-DrawioFile {
    param(
        [string]$xmlFilePath,
        [string]$xsltFilePath
    )

    $xmlReader = [System.Xml.XmlReader]::Create($xmlFilePath)

    $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
    $xslt.Load($xsltFilePath)

    $output = New-Object System.IO.StringWriter
    $xslt.Transform($xmlReader, $null, $output)

    $xmlReader.Close()
    
    return $output.ToString()
}

$files1 = Get-ChildItem -Path $path1 -Filter "*.drawio" -File -Recurse
$files2 = Get-ChildItem -Path $path2 -Filter "*.drawio" -File -Recurse

$outputLines = @()

foreach ($file1 in $files1) {
    $matchingFile = $files2 | Where-Object { $_.Name -eq $file1.Name -and $_.FullName -replace [regex]::Escape($path2), $path1 }

    if ($matchingFile) {
        $xml1 = Transform-DrawioFile -xmlFilePath $file1.FullName -xsltFilePath $xsltFilePath
        $xml2 = Transform-DrawioFile -xmlFilePath $matchingFile.FullName -xsltFilePath $xsltFilePath

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
