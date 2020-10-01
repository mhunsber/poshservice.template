function Invoke-Nssm {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Command,
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$ArgumentList
    )
    $nssmPath = (Get-Command -Name 'nssm.exe' -CommandType Application -ErrorAction Stop).Definition
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = $nssmPath
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $nssmVersion = (Get-Item -Path $nssmPath).VersionInfo.FileVersion
    if ($nssmVersion -lt [version]'2.24.101') {
        # This fixes a whitespace issue with nssm prior to 2.24.101 (https://groups.google.com/g/salt-users/c/DTstUL3qHzk/m/K9YZQFG5CgAJ)
        $pinfo.StandardOutputEncoding = [System.Text.Encoding]::Unicode
        $pinfo.StandardErrorEncoding = [System.Text.Encoding]::Unicode
    }
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = (,$Command + $ArgumentList | ForEach-Object { '"' + $_.Replace('"','\"') + '"' } ) -join ' '
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $pinfo
    $p.Start() | Out-Null
    $p.WaitForExit()
    $stderr = $p.StandardError.ReadToEnd().Trim()
    $stdout = $p.StandardOutput.ReadToEnd().Trim()
    if($stderr) {
        Write-Error -Message $stderr
    }
    Write-Output $stdout
    $LASTEXITCODE = $p.ExitCode
    $p.Dispose()
}
