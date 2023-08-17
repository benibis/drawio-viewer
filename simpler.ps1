function Get-DrawioXmlValue {
    param(
        [string]$filePath,
        [string]$tagName
    )

    $xml = New-Object System.Xml.XmlDocument
    $xml.Load($filePath)
    
    $value = $xml.SelectSingleNode("//mxfile/$tagName").Attributes["value"].Value
    return $value
}

$filePath1 = "PathToFirstFile.drawio"
$filePath2 = "PathToSecondFile.drawio"
$tagName = "SomeTagName"

$value1 = Get-DrawioXmlValue -filePath $filePath1 -tagName $tagName
$value2 = Get-DrawioXmlValue -filePath $filePath2 -tagName $tagName

Write-Host "Value in File 1: $value1"
Write-Host "Value in File 2: $value2"
