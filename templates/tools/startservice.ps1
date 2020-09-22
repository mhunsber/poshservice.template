[cmdletbinding()]
param()
$ea = $ErrorActionPreference
$ErrorActionPreference = 'Stop' # until we are ready for the loop
if ($env:PSS_VERBOSELOG -eq '1') { $VerbosePreference = 'Continue' }
if (-not $env:PSS_MAXLOGFILES) { $env:PSS_MAXLOGFILES = 100 }
# We pass ServiceName to the script as an environment variable so that we can query service parameters
# from nssm. This also ensures the service name used by the chocolatey install script lines up with the servicename used by the script.
if (-not $env:PSS_SERVICENAME) { Write-Error -Message "Missing required environment variable PSS_SERVICENAME. Verify service installation." }

Get-ChildItem -Recurse -File -Path "$PSScriptRoot\functions", "$PSScriptRoot\include" -Filter '*.ps1' -Exclude '*.tests.*' | ForEach-Object {
    Write-Verbose "importing $($_.FullName)..."
    . $_.FullName
}

$RotateLogs = (Invoke-Nssm get $env:PSS_SERVICENAME approtatefiles 2>$null -ErrorAction Continue) -eq '1'
# Log Rotation (this is all because nssm's online rotation doesn't behave as expected)
if ($RotateLogs) {
    # using New-ScheduledJob would be easier, but requires administrator rights, which the service user might not have
    $logRotationJob = Start-Job -Name RotateLogs -ScriptBlock ${Function:Reset-NssmServiceLogs} `
        -InitializationScript ([scriptblock]::Create("
            function Invoke-Nssm { ${Function:Invoke-Nssm} }
            function Get-NextExecutionTime { ${Function:Get-NextExecutionTime} }
        ")) -ArgumentList $env:PSS_SERVICENAME, $env:PSS_ROTATEEVERY, $env:PSS_MAXLOGFILES
}
try {
    . startup
    $ErrorActionPreference = $ea # reset error action preference
    while($true) {
        if($RotateLogs) {
            Receive-Job -Job $logRotationJob # receive and clear the output
        }
        . run
        Start-Sleep -Milliseconds $MSDELAY
    }
} finally {
    # For some reason at this point "Write-Host" is required for nssm to display the output in the log file.
    Write-Host "Stopping service..."
    if ($RotateLogs) {
        Stop-Job -Job $logRotationJob
        Receive-Job -Job $logRotationJob | Write-Host
        Remove-Job -Job $logRotationJob
    }
    . cleanup | Write-Host
    Write-Host "Ended"
}
