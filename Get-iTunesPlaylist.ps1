## Code based on urulokis "Get-AlbumsfromItunes.ps1": https://gist.github.com/uruloki/bd19cbe5d2461cfd7715

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Path
)

[xml]$xml = Get-Content $path -Encoding utf8

if ($null -eq $xml) {
    Write-Host "ERROR: Path or file is invalid" -ForegroundColor Red
    Break
}

function Get-ValueForAppleDictionaryKey {
    param (
        [Parameter(ValueFromPipeline = $true)]
        [ValidateScript({
            if ($_.Name -eq 'dict') { return $true }
            throw 'Only elements may be passed to this command'
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

$id = $xml.plist.dict | 
Get-ValueForAppleDictionaryKey -KeyName Tracks -ValueType dict |
Get-ValueForAppleDictionaryKey -ValueType dict | 
Get-ValueForAppleDictionaryKey -KeyName "Track ID" -ValueType integer

$artist = $xml.plist.dict |
Get-ValueForAppleDictionaryKey -KeyName Tracks -ValueType dict |
Get-ValueForAppleDictionaryKey -ValueType dict |
Get-ValueForAppleDictionaryKey -KeyName Artist -ValueType string

$name = $xml.plist.dict |
Get-ValueForAppleDictionaryKey -KeyName Tracks -ValueType dict |
Get-ValueForAppleDictionaryKey -ValueType dict |
Get-ValueForAppleDictionaryKey -KeyName Name -ValueType string

$bpm = $xml.plist.dict |
Get-ValueForAppleDictionaryKey -KeyName Tracks -ValueType dict |
Get-ValueForAppleDictionaryKey -ValueType dict |
Get-ValueForAppleDictionaryKey -KeyName BPM -ValueType integer

$grouping = $xml.plist.dict |
Get-ValueForAppleDictionaryKey -KeyName Tracks -ValueType dict |
Get-ValueForAppleDictionaryKey -ValueType dict |
Get-ValueForAppleDictionaryKey -KeyName Grouping -ValueType string

# Output title
$xml.plist.dict.array.dict.string[0]
Write-Host ""

# Output tracks to variable
$track = 0
$alltracks = while ($null -ne $artist[$track]) {      
    "$(($artist[$track]).InnerText) - $(($name[$track]).InnerText);$(($bpm[$track]).InnerText);$(($grouping[$track]).InnerText);$(($id[$track]).InnerText)"
    $track++
}

# Sort tracks from variable
$trackorder = $xml.plist.dict.array.dict.array.dict.integer
$trackorder | ForEach-Object {
    $trackid = $_
    $output = $alltracks | Where-Object {$_ -like "*$trackid"}
    # Remove ID from output
    $output = $output -replace ";$trackid"
    $output
}