$ErrorActionPreference = 'Stop';
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$ScriptName = 'startservice'

Get-ChildItem -Recurse -File -Path "$toolsDir\functions" -Filter '*.ps1' -Exclude '*.tests.*' | ForEach-Object {
    Write-Verbose "importing $($_.FullName)..."
    . $_.FullName
}

$ServiceConfig = Import-PowerShellDataFile -Path "$toolsDir\$ScriptName.psd1"
if ([string]::IsNullOrWhiteSpace($ServiceConfig.Name)) { $ServiceConfig.Name = $env:ChocolateyPackageName }
if ([string]::IsNullOrWhiteSpace($ServiceConfig.DisplayName)) { $ServiceConfig.DisplayName = $env:ChocolateyPackageTitle }

if (Get-Service $ServiceConfig.Name -ErrorAction SilentlyContinue) {
    Invoke-Nssm remove $ServiceConfig.Name confirm
}
