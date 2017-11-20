param (
    [Parameter(Mandatory=$true)][int]$activeOnly
    ,[Parameter(Mandatory=$true)][int]$openFile
)

function MakeBITRLink ([string]$text) {
    select-string $Settings.Settings.Notes.RegexString -InputObject $text -AllMatches | foreach {
        foreach ($match in $_.Matches) {
            $linkString = $([string]::Format($HTMLSnippets.Items.Notes.Six.'#cdata-section',$match.Value))
            $text = $text.Replace($match.Value,$linkString)
        }
    }
    $text
}
    
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
[xml]$Settings = Get-Content -Path (Join-Path $PSScriptRoot "Resources\config.xml")
[xml]$HTMLSnippets = Get-Content -Path (Join-Path $PSScriptRoot "Resources\htmlsnippets.xml")
$fileName = $Settings.Settings.Notes.XML
$xmlDoc = [System.Xml.XmlDocument](Get-Content $fileName)

$sep = $("").PadRight(185,"-")
$file = (join-path $Settings.Settings.Notes.OutputDirectory $Settings.Settings.Notes.OutputFile)
$notesarray = ""
$head = $([string]::Format($HTMLSnippets.Items.Notes.One.'#cdata-section',$(if ($activeOnly -eq "1") {"Active"} else {"Active and Inactive"})))
$xmlDoc.Items.BITR | sort @{expression={if ($_.followupdate -ne "") {$_.followupdate} else {(get-date "1900-01-01")}}} | foreach {
    if (($_.active -eq "1") -or (($activeOnly -eq "0") -and ($_.status -ne "Released"))) {
        $notesarray += [string]::Format($HTMLSnippets.Items.Notes.Two.'#cdata-section',$_.ID, $(if($_.active -eq "1") {"Active"} else {"Inactive"}),$_.status,$_.Owner,$_.Name,$(MakeBITRLink $_.Description),$_.followupdate)
        $_.Comment | Sort date -Descending  | foreach {
            $notesarray += ([string]::Format($HTMLSnippets.Items.Notes.Three.'#cdata-section',$(Get-Date $_.date -Format "yyyy-MM-dd"),$(MakeBITRLink $_.text)))
        }
        $notesarray += $HTMLSnippets.Items.Notes.Four.'#cdata-section'
    }
}
$notesarray = [string]::Format("{0} {1} {2} {3}",$head, $HTMLSnippets.Items.Notes.OnePointFive.'#cdata-section',$notesarray,$HTMLSnippets.Items.Notes.Five.'#cdata-section')
[IO.File]::WriteAllLines($file, $notesarray)
if ($openFile -eq "1") {
    Invoke-Item $file
}
