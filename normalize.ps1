param(
    [string]$path1,
    [string]$path2,
    [string]$xsltFilePath
)

$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$outputFilePath = Join-Path (Get-Item $path2).Parent.FullName ("$timestamp-drawio-compare.txt")

function Transform-DrawioFile {
    param(
        [string]$xmlFilePath,
        [string]$xsltFilePath
    )

    $xmlReader = [System.Xml.XmlReader]::Create($xmlFilePath)

    $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
    $xslt.Load($xsltFilePath)

    $output = New-Object System.IO.StringWriter

    # Move to the next node, skipping the BOM if present
    while ($xmlReader.NodeType -eq [System.Xml.XmlNodeType]::Whitespace) {
        $xmlReader.Read()
    }

    $xslt.Transform($xmlReader, $null, $output)

    $xmlReader.Close()

    $output.ToString()
}

$normalizedPath1 = "${path1}-normalized"
$normalizedPath2 = "${path2}-normalized"

# Create normalized directories
New-Item -Path $normalizedPath1 -ItemType Directory -Force
New-Item -Path $normalizedPath2 -ItemType Directory -Force

# Apply the XSLT transformation to each file in the original directories and store in a variable
$normalizedFiles1 = Get-ChildItem -Path $path1 -Filter "*.drawio" -File -Recurse | ForEach-Object {
    $normalizedFilePath = $_.FullName -replace [regex]::Escape($path1), $normalizedPath1
    $transformedContent = Transform-DrawioFile -xmlFilePath $_.FullName -xsltFilePath $xsltFilePath
    [PSCustomObject]@{
        FilePath = $normalizedFilePath
        Content  = $transformedContent
    }
}

$normalizedFiles2 = Get-ChildItem -Path $path2 -Filter "*.drawio" -File -Recurse | ForEach-Object {
    $normalizedFilePath = $_.FullName -replace [regex]::Escape($path2), $normalizedPath2
    $transformedContent = Transform-DrawioFile -xmlFilePath $_.FullName -xsltFilePath $xsltFilePath
    [PSCustomObject]@{
        FilePath = $normalizedFilePath
        Content  = $transformedContent
    }
}

# Compare the normalized directories
$normalizedFiles1 | ForEach-Object {
    $matchingFile = $normalizedFiles2 | Where-Object { $_.FilePath -eq $_.FilePath -replace [regex]::Escape($normalizedPath1), $normalizedPath2 }

    if ($matchingFile) {
        $xml1 = $_.Content
        $xml2 = $matchingFile.Content

        if ($xml1 -ne $xml2) {
            $outputLines += ("Differences found in $($_.FilePath) and $($matchingFile.FilePath):")
            
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
        $outputLines += ("File $($_.FilePath) does not exist in the second directory.")
    }
}

# Clean up: delete the normalized directories
Remove-Item -Path $normalizedPath1 -Force -Recurse
Remove-Item -Path $normalizedPath2 -Force -Recurse

if ($outputLines.Count -gt 0) {
    $outputLines | Set-Content -Path $outputFilePath
    Write-Host "Differences written to $($outputFilePath)"
} else {
    Write-Host "No differences found."
}
