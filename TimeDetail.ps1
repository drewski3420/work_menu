$sql = $args[0]
$txt = $args[1]

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
[xml]$Settings = Get-Content -Path (Join-Path $PSScriptRoot "Resources\config.xml")

$a = (Invoke-Sqlcmd -InputFile $sql -ServerInstance $Settings.Settings.Server.ServerInstance -Database $Settings.Settings.Server.Database)
$cnt = 0
$resultarray = @() 
$file = $txt
foreach ($thing in $a) {
    if ($cnt -eq 0) {
        $resultarray += "------------------"
        $resultarray += [string]::Format("{0} | {1} | {2} | {3}",$("#").Tostring().Padright(2," "),$thing.Table.Columns[1].ColumnName.Padleft(2," "),$thing.Table.Columns[2].ColumnName.Padleft(2," "),$thing.Table.Columns[0].ColumnName.PadRight(3," "))
        $resultarray += "------------------"
    }
    $resultarray += [string]::Format("{0} | {1} | {2} | {3}",$($cnt + 1).Tostring().Padright(2," "),$thing.H.ToString().Padleft(2," "),$thing.M.ToString().Padleft(2," "),$thing.ID.ToString().PadRight(3," "))
    $cnt += 1
}
$resultarray += "------------------"
$resultarray | Out-File $file