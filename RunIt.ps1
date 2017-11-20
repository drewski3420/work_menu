param (
    [Parameter(Mandatory=$true)][string]$PS1,
    [Parameter(Mandatory=$true)][string]$TXT,
    [Parameter(Mandatory=$true)][string]$SQL
)
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
[xml]$Settings = Get-Content -Path (Join-Path $PSScriptRoot "Resources\config.xml")

$script = (Join-Path $Settings.Settings.Paths.PSScript $PS1)
$file = (Join-Path $Settings.Settings.Paths.ScriptOutput $TXT)
$sql = (Join-Path $Settings.Settings.Paths.SQLScript $SQL)
$cmd = "$($script) '$sql' '$file'"
Invoke-Expression $cmd
Invoke-Item $file
