$ErrorActionPreference = 'Stop';
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$ScriptName = 'startservice'

$ServiceConfig = Import-PowerShellDataFile -Path "$toolsDir\$ScriptName.psd1"
if ([string]::IsNullOrWhiteSpace($ServiceConfig.Name)) { $ServiceConfig.Name = $env:ChocolateyPackageName }
if ([string]::IsNullOrWhiteSpace($ServiceConfig.DisplayName)) { $ServiceConfig.DisplayName = $env:ChocolateyPackageTitle }

if (Get-Service $ServiceConfig.Name -ErrorAction SilentlyContinue) {
    Stop-Service -Name $ServiceConfig.Name -ErrorAction Continue
    Start-Sleep -Seconds 1
    $defaultEncoding = [System.Console]::OutputEncoding
    [System.Console]::OutputEncoding = [System.Text.Encoding]::Unicode # otherwise nssm outputs weird spacing
    try {
        nssm remove $ServiceConfig.Name confirm
    } finally {
        [System.Console]::OutputEncoding = $defaultEncoding
    }
}


