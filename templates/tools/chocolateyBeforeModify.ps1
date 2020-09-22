$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$ScriptName = 'startservice'

$ServiceConfig = Import-PowerShellDataFile -Path "$toolsDir\$ScriptName.psd1"
if ([string]::IsNullOrWhiteSpace($ServiceConfig.Name)) { $ServiceConfig.Name = $env:ChocolateyPackageName }
if ([string]::IsNullOrWhiteSpace($ServiceConfig.DisplayName)) { $ServiceConfig.DisplayName = $env:ChocolateyPackageTitle }

$service = Get-Service $ServiceConfig.Name -ErrorAction SilentlyContinue
if ($service) {
    $env:PreviousServiceStatus = $service.Status # set for install script
    Stop-Service -Name $ServiceConfig.Name -ErrorAction Continue
    Start-Sleep -Seconds 1
}
