param(
    [string]$VivadoCmd = "vivado"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$tclPath = Join-Path $scriptDir "run_admin_flow_xsim.tcl"

Push-Location $scriptDir
try {
    & $VivadoCmd -mode batch -source $tclPath
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
