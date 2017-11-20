#cls
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
[xml]$Settings = Get-Content -Path (Join-Path $PSScriptRoot "Resources\config.xml")
$console = $host.UI.RawUI
$console.WindowTitle = $Settings.Settings.APOD.MenuTitle
$c = 0

function FormatString([String]$expl) {
    $explArray = $expl.toString() -split " "
    $r = ""
    $return = ""
    $flag = 0
    foreach ($item in $explArray) {
        if ($item -eq $Settings.Settings.APOD.Exclusion) {} #explanation lable - ignore
        elseif ($r -eq "") { #if first word on line, no leading space
            $r += $item
        }
        elseif ($r.Length -lt $Settings.Settings.APOD.LineLength) {#if length line less than X chars, add word to line
            $r = [string]::Format("{0} {1}",$r,$item)
        }
        else { #line length greater X chars, add line to return var, then start new line
            $return += "`r`n"
            $return += $r
            $r = $item
        }
    }
    $return = [string]::Format("{0}{1}{2}{1}{1}",$return,"`r`n",$r)
    return $return
}

try { #look for today's picture
    $final = (join-path $Settings.Settings.APOD.DestDirectory  $Settings.Settings.APOD.DestFile)
    $stem = $Settings.Settings.APOD.Source

    $out = (invoke-webrequest -uri ([string]::Format("{0}{1}",$stem,$Settings.Settings.APOD.URLFilename))).ParsedHTML
    $img = $out.getElementsbytagname("a")
    foreach ($i in $img) {  
        if ($i.Pathname -like 'image*') {
            $path = $i.Pathname
            break
        }
    }
    if (($path -eq "") -or ($path -eq $null)) { #today's picture wasn't found, so start looping through previous days
        throw "error" 
    }
}
catch { #couldn't find a path, so look at previous days
    do {
        $c = $c - 1
        $dt = ((get-date).AddDays($c)).ToString("yyMMdd")
        $out = (Invoke-WebRequest -Uri ([string]::Format("{0}ap{1}.html",$stem,$dt))).ParsedHTML
        $img = $out.getElementsbytagname("a")
        foreach ($i in $img) {  
            if ($i.Pathname -like 'image*') {
                $path = $i.Pathname
                break
            }
        }

        if (($path -ne "") -and ($path -ne $null)) {
            break
        }
    } until ($false)
}
finally {#we found a path somewhere. keep going
    Invoke-WebRequest -Uri ([string]::Format("{0}{1}",$stem,$path)) -OutFile $final
    $cmd = [string]::Format("{0} {1} -timer:0",$Settings.Settings.Paths.BGInfo,$Settings.Settings.Paths.BGInfoConfig)
    Invoke-Expression $cmd

    $f = $out.getElementsByTagName("p")
    foreach ($i in $f) {
        If ($i.innerText -like 'Explanation*') {
            $expl = $i.innertext
            break
        }
    }
    $abc = formatstring($expl)
    write-host $abc
    Read-Host "Continue"
} 


