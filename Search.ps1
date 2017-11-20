param (
    [Parameter(Mandatory=$true)][string]$searchfor
)
cls
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
[xml]$Settings = Get-Content -Path (Join-Path $PSScriptRoot "Resources\config.xml")
[xml]$HTMLSnippets = Get-Content -Path (Join-Path $PSScriptRoot "Resources\htmlsnippets.xml")

$resultArray = @()
$searchResults = @()
$searchForRay = @()
$searchforRay = $searchfor.Split(" ")
$searchForRay = $searchForRay[1..($searchForRay.Length-1)]
$file = (join-path $Settings.Settings.Paths.ScriptOutput $Settings.Settings.Search.SearchOutput)
$searchResults = Get-ChildItem $Settings.Settings.Paths.SQL -recurse #| Select-String -Pattern $searchfor 

foreach ($item in $searchResults) {
    $matchFound = 0
    [string]$text = $item | Get-Content
    for ($i = 0; $i -lt $searchForRay.Length; $i++) {
        if ($text -match $searchForRay[$i]) {
            $matchFound += 1
        }
    }
    if ($matchFound -eq $searchForRay.Length) {$resultArray += ,@($item.FullName)}
}

$resultArray = $resultArray | sort-object
$resultArray = $resultArray | Get-Unique -AsString
$searchTerm = ([string]::Format($HTMLSnippets.Items.Search.Three.'#cdata-section',$([string]$searchForRay)))
foreach ($result in $resultArray) {
    $resultString += ([string]::Format($HTMLSnippets.Items.Search.Four.'#cdata-section',[string]$result, [string]$result))
}
$t = [string]::Format($HTMLSnippets.Items.Search.One.'#cdata-section',$([string]$searchForRay))
$finalString = [string]::Format("{0} {1} {2} {3} {4}",$t,$HTMLSnippets.Items.Search.Two.'#cdata-section',$searchTerm,$resultString,$HTMLSnippets.Items.Search.Five.'#cdata-section')
[IO.File]::WriteAllLines($file, $finalString)
Invoke-Item $file
