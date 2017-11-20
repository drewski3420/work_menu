$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
[xml]$Settings = Get-Content -Path (Join-Path $PSScriptRoot "Resources\config.xml")
[xml]$Items = Get-Content -Path (Join-Path $PSScriptRoot "Resources\items.xml")
$console = $host.UI.RawUI
$console.WindowTitle = $Settings.Settings.Backup.Title

$backups = $Items.Items.Backups

foreach ($backup in $backups.Backup) {
    Write-Host $([string]::Format("Processing {0}",$backup.Name))
    $dest = $Settings.Settings.Backup.Dest
    $dest = (join-path(join-path $dest $(get-date -Format yyyyMMdd)) $backup.FolderName)
    $exclude = @()
    foreach ($e in $backup.Exclusions.Exclusion) {
        write-host $([string]::Format("Excluding {0}",$e))
        $exclude += ,@($e)
    }
    
    foreach ($w in (Get-ChildItem $backup.Source)) {
        $match = 0
         
        foreach ($e in $exclude) {
            if ($w.FullName -match $e) {
                $match = 1
            }
        }
        try {
            if ($match -eq 0) {
                if ((Get-Item $w.FullName) -is [System.IO.DirectoryInfo]) {
                    $s = (get-item $w.FullName).Parent.FullName.ToString() -replace "\\","\\"
                }
                else {
                    $s = (get-item $w.FullName).Directory.FullName.ToString() -replace "\\","\\"
                }
                $r = $dest -replace "\\","\\"
                Write-Host $([string]::Format("Backing up {0}",$w.Name))
                [void](New-Item -ItemType directory -Force $r)
                Copy-Item $w.FullName ($w.FullName -replace  $s, $r) -Recurse -Force
            }        
        }
        catch {
            write-host $([string]::Format("Unable to find {0}",$w.Name))
        }
    }
}