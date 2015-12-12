# http://powershell.org/wp/forums/topic/itunes-xml/
# 
#$song = $top.plist.dict | Get-ValueForAppleDictionaryKey -KeyName Tracks -ValueType dict | Get-ValueForAppleDictionaryKey -ValueType dict | Get-ValueForAppleDictionaryKey -KeyName Name -ValueType string | ForEach-Object { $_.InnerText } | Get-Unique
#$artist = $top.plist.dict | Get-ValueForAppleDictionaryKey -KeyName Tracks -ValueType dict | Get-ValueForAppleDictionaryKey -ValueType dict | Get-ValueForAppleDictionaryKey -KeyName Artist -ValueType string | ForEach-Object { $_.InnerText } | Get-Unique
#$rating = $top.plist.dict | Get-ValueForAppleDictionaryKey -KeyName Tracks -ValueType dict | Get-ValueForAppleDictionaryKey -ValueType dict | Get-ValueForAppleDictionaryKey -KeyName Rating -ValueType integer | ForEach-Object { $_.InnerText }
#
# Other ref:
#     http://blogs.technet.com/b/heyscriptingguy/archive/2012/03/26/use-powershell-to-parse-an-xml-file-and-sort-the-data.aspx


function Import-AlbumsFromStupidITunesXml
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if (Test-Path -LiteralPath $_)
            {
                return $true
            }

            throw "Path '$_' does not exist."
        })]
        [string]
        $Path
    )

    $xml = [xml](Get-Content -LiteralPath $Path)

    $xml.plist.dict |
    Get-ValueForAppleDictionaryKey -KeyName Tracks -ValueType dict |
    Get-ValueForAppleDictionaryKey -ValueType dict |
    Get-ValueForAppleDictionaryKey -KeyName Album -ValueType string |
    ForEach-Object { $_.InnerText } |
    Get-Unique
}

function Get-ValueForAppleDictionaryKey
{
    param (
        [Parameter(ValueFromPipeline = $true)]
        [ValidateScript({
            if ($_.Name -eq 'dict') { return $true }
            throw 'Only  elements may be passed to this command'
        })]
        [System.Xml.XmlElement]
        $Dictionary,

        [string]
        $KeyName,

        [ValidateSet('integer', 'string', 'dict')]
        [string]
        $ValueType
    )

    process
    {
        if ($null -eq $Dictionary)
        {
            return
        }

        $childCount = $Dictionary.ChildNodes.Count

        for ($i = 0; $i -lt $childCount-1; $i++)
        {
            $node = $Dictionary.ChildNodes[$i]
            $nextNode = $Dictionary.ChildNodes[$i + 1]

            if ($node.Name -eq 'key' -and
                ([string]::IsNullOrEmpty($KeyName) -or $node.InnerText -eq $KeyName) -and
                ([string]::IsNullOrEmpty($ValueType) -or $nextNode.Name -eq $ValueType))
            {
                $nextNode
                $i++
            }
        }
    }
}

$albums = Import-AlbumsFromStupidITunesXml -Path '.\test.xml'
$albums