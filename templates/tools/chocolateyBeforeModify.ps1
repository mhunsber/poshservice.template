$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$ScriptName = 'startservice'

$ServiceConfig = Import-PowerShellDataFile -Path "$toolsDir\$ScriptName.psd1" -ErrorAction SilentlyContinue
if ([string]::IsNullOrWhiteSpace($ServiceConfig.Name)) { $ServiceConfig.Name = $env:ChocolateyPackageName }
if ([string]::IsNullOrWhiteSpace($ServiceConfig.DisplayName)) { $ServiceConfig.DisplayName = $env:ChocolateyPackageTitle }
if (!$ServiceConfig.ShutdownTimeout) { $ServiceConfig.ShutdownTimeout = 5000 }

$service = Get-Service $ServiceConfig.Name -ErrorAction SilentlyContinue
if ($service) {
    $env:PreviousServiceStatus = $service.Status # set for install script
    $service | Stop-Service -NoWait -ErrorAction Continue
    $timeout = New-TimeSpan -Seconds (($ServiceConfig.ShutdownTimeout/1000) + 10)
    $service.WaitForStatus('Stopped', $timeout)
    Start-Sleep -Seconds 2 # give time for nssm to actually exit. Otherwise Chocolatey will try to remove the working directory while nssm is still running
}
