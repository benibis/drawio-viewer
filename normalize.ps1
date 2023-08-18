param(
    [string]$path1,
    [string]$path2,
    [string]$xsltFilePath
)

$normalizedPath1 = "${path1}-normalized"
$normalizedPath2 = "${path2}-normalized"

# Create normalized directories
New-Item -Path $normalizedPath1 -ItemType Directory -Force
New-Item -Path $normalizedPath2 -ItemType Directory -Force

# Apply the XSLT transformation to each file in the original directories and copy to normalized directories
Get-ChildItem -Path $path1 -Filter "*.drawio" -File -Recurse | ForEach-Object {
    $normalizedFilePath = $_.FullName -replace [regex]::Escape($path1), $normalizedPath1
    Transform-DrawioFile -xmlFilePath $_.FullName -xsltFilePath $xsltFilePath | Set-Content -Path $normalizedFilePath
}

Get-ChildItem -Path $path2 -Filter "*.drawio" -File -Recurse | ForEach-Object {
    $normalizedFilePath = $_.FullName -replace [regex]::Escape($path2), $normalizedPath2
    Transform-DrawioFile -xmlFilePath $_.FullName -xsltFilePath $xsltFilePath | Set-Content -Path $normalizedFilePath
}

# Compare the normalized directories
.\Compare-Drawio-Files.ps1 -path1 $normalizedPath1 -path2 $normalizedPath2

# Clean up: delete the normalized directories
Remove-Item -Path $normalizedPath1 -Force -Recurse
Remove-Item -Path $normalizedPath2 -Force -Recurse
