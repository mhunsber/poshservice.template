﻿$ErrorActionPreference = 'Stop';
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$pp = Get-PackageParameters
$ScriptName = 'startservice'

$ServiceConfig = Import-PowerShellDataFile -Path "$toolsDir\$ScriptName.psd1"
if ([string]::IsNullOrWhiteSpace($ServiceConfig.Name)) { $ServiceConfig.Name = $env:ChocolateyPackageName }
if ([string]::IsNullOrWhiteSpace($ServiceConfig.DisplayName)) { $ServiceConfig.DisplayName = $env:ChocolateyPackageTitle }

$poshservice_home = "$env:ProgramData\PoSHServices"
if ([string]::IsNullOrWhiteSpace($ServiceConfig.Logging.Path)) {
    $ServiceConfig.Logging.Path = "$poshservice_home\$($ServiceConfig.Name)\$($ServiceConfig.Name).log"
} elseif(-not [System.IO.Path]::IsPathRooted($ServiceConfig.Logging.Path)) {
    $ServiceConfig.Logging.Path = Join-Path -Path $toolsDir -ChildPath $ServiceConfig.Logging.Path
}
$logDirectory = Split-Path -Path $ServiceConfig.Logging.Path
if (!(Test-Path -Path $logDirectory)) {
    New-Item -Path $logDirectory -ItemType Directory | Out-Null
}

Write-Output "$($ServiceConfig.Name) log output path: <$($ServiceConfig.Logging.Path)>"

$ScriptFullPath = Join-Path -Path $toolsDir -ChildPath "$ScriptName.ps1"

$Arguments = '-ExecutionPolicy Bypass -NoProfile -File "{0}"' -f $ScriptFullPath
$defaultEncoding = [System.Console]::OutputEncoding
[System.Console]::OutputEncoding = [System.Text.Encoding]::Unicode # otherwise nssm outputs weird spacing
try {
    # install or update
    if (Get-Service -Name $ServiceConfig.Name -ErrorAction Ignore) {
        nssm set $ServiceConfig.Name application powershell.exe
        nssm set $ServiceConfig.Name appparameters $Arguments
    } else {
        nssm install $ServiceConfig.Name powershell.exe $Arguments
    }

    nssm set $ServiceConfig.Name appdirectory $toolsDir

    # service display options
    nssm set $ServiceConfig.Name displayname $ServiceConfig.DisplayName
    if (![string]::IsNullOrWhiteSpace($ServiceConfig.Description)) {
        nssm set $ServiceConfig.Name description $ServiceConfig.Description
    }

    # service run context
    switch($ServiceConfig.RunAs) {
        'LOCALSYSTEM' {
            nssm reset $ServiceConfig.Name objectname
            break
        }
        'NETWORKSERVICE' {
            nssm set $ServiceConfig.Name objectname networkservice
            break
        }
        'LOCALSERVICE' {
            nssm set $ServiceConfig.Name objectname localservice
            break
        }
        default {
            $creds = Get-Credential -UserName $ServiceConfig.RunAs -Message "Enter the account credentials for $($ServiceConfig.Name) to run under. For the username, be sure to use <domain>\<username>. For local accounts, <domain> is '.'."
            nssm set $ServiceConfig.Name objectname $creds.UserName $creds.GetNetworkCredential().Password
            break
        }
    }

    switch ($ServiceConfig.Startup) {
        { 'SERVICE_AUTO_START', 'AUTOMATIC' -contains $_ } {
            nssm set $ServiceConfig.Name start SERVICE_AUTO_START
            break
        }
        { 'SERVICE_DELAYED_AUTO_START', 'DELAYED', 'AUTOMATIC (DELAYED START)' -contains $_ } {
            nssm set $ServiceConfig.Name start SERVICE_DELAYED_AUTO_START
            break
        }
        { 'SERVICE_DEMAND_START', 'MANUAL' -contains $_ } {
            nssm set $ServiceConfig.Name start SERVICE_DEMAND_START
            break
        }
        { 'SERVICE_DISABLED', 'DISABLED' -contains $_ } {
            nssm set $ServiceConfig.Name start SERVICE_DISABLED
            break
        }
        default {
            Write-Warning -Message "Expected Startup to be one of 'SERVICE_AUTO_START|SERVICE_DELAYED_START|SERVICE_DEMAND_START|SERVICE_DISABLED', but was '$_'."
            break
        }
    }

    # give the service user permissions to write/rotate logs
    $runas = nssm get $ServiceConfig.Name objectname # nssm normalizes the name
    $acl = Get-Acl -Path $logDirectory
    $ace = New-Object System.Security.AccessControl.FileSystemAccessRule -ArgumentList $runas, 'Read,Write,Synchronize,DeleteSubdirectoriesAndFiles', 'ContainerInherit,ObjectInherit', 'None', 'Allow'
    $acl.AddAccessRule($ace)
    Set-Acl -Path $logDirectory -AclObject $acl

    # io redirection
    nssm set $ServiceConfig.Name appstdout $ServiceConfig.Logging.Path
    nssm set $ServiceConfig.Name appstderr $ServiceConfig.Logging.Path
    nssm set $ServiceConfig.Name approtatefiles "$([int]$ServiceConfig.Logging.Rotate.Enabled)"
    nssm set $ServiceConfig.Name approtateonline "$([int]$ServiceConfig.Logging.Rotate.Enabled)"

    # shutdown parameters
    nssm set $ServiceConfig.Name appexit default exit
    if ($ServiceConfig.ShutdownTimeout) {
        nssm set $ServiceConfig.Name appstopmethodconsole $ServiceConfig.ShutdownTimeout
    }

    # environment variables
    $currentVars = nssm get $ServiceConfig.Name appenvironmentextra
    $newVars = @{
        PSS_SERVICENAME=$ServiceConfig.Name
        PSS_VERBOSELOG="$([int]$ServiceConfig.Logging.Verbose)"
        PSS_ROTATEEVERY="$($ServiceConfig.Logging.Rotate.Every)"
        PSS_MAXLOGFILES="$($ServiceConfig.Logging.Rotate.KeepFiles)"
    }
    $finalVars = @{}
    foreach($key in $currentVars.Keys) {
        $finalVars.$key = $currentVars.$key
    }
    # override any current environment variables
    foreach($key in $newVars.Keys) {
        $finalVars.$key = $newVars.$key
    }
    $environment = foreach($entry in $finalVars.GetEnumerator()) { "$($entry.key)=$($entry.value)" }
    nssm set $ServiceConfig.Name appenvironmentextra @environment

    # Make the service definition readonly so we don't change before an uninstall or update
    Set-ItemProperty -Path "$toolsDir\$ScriptName.psd1" -Name IsReadOnly -Value $True
} finally {
    [System.Console]::OutputEncoding = $defaultEncoding
}

if($pp['STARTNOW'] -or $env:PreviousServiceStatus -eq 'Running') {
    Start-Service -Name $ServiceConfig.Name -ErrorAction Continue
}