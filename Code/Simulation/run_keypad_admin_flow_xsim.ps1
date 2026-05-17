param(
    [string]$VivadoCmd = "vivado"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$tclPath = Join-Path $scriptDir "run_keypad_admin_flow_xsim.tcl"

Get-Command $VivadoCmd -ErrorAction Stop | Out-Null

Push-Location $scriptDir
try {
    & $VivadoCmd -mode batch -source $tclPath
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
