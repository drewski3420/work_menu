$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
[xml]$Settings = Get-Content -Path (Join-Path $PSScriptRoot "Resources\config.xml")
Invoke-Expression $([string]::Format("powershell -WindowStyle Hidden -file {0}",$Settings.Settings.Paths.Menu))