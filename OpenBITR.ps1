$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
[xml]$Settings = Get-Content -Path (Join-Path $PSScriptRoot "Resources\config.xml")
$BITRstem   = $Settings.Settings.BITR.URL

$BITRID = (Read-Host ("Enter a BITR number"))
if ($BITRID -ne "") {
    $url = $BITRstem + $BITRID

    Start-Process -FilePath "$url"
}