param (
    [Parameter(Mandatory=$true)][string]$process
)


Stop-Process -name $process -ErrorAction SilentlyContinue
