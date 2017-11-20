param (
    [Parameter(Mandatory=$true)][string]$process,
    [Parameter(Mandatory=$true)][string]$exe
)
$proc = Get-Process -name $process -ErrorAction SilentlyContinue 
If (-not $proc) { #proc not already running
	Start-Process $exe
}