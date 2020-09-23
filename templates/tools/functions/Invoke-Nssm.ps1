function Invoke-Nssm {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Command,
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$ArgumentList
    )
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = 'nssm.exe'
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    # This fixes a whitespace issue with nssm (https://groups.google.com/g/salt-users/c/DTstUL3qHzk/m/K9YZQFG5CgAJ)
    $pinfo.StandardOutputEncoding = [System.Text.Encoding]::Unicode
    $pinfo.StandardErrorEncoding = [System.Text.Encoding]::Unicode
    $pinfo.UseShellExecute = $false
    $pinfo.Arguments = (,$Command + $ArgumentList | ForEach-Object { '"' + $_.Replace('"','\"') + '"' } ) -join ' '
    $p = New-Object System.Diagnostics.Process
    Write-Verbose -Message ('starting process: {0} {1}' -f $pinfo.FileName, $pinfo.Arguments)
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
}
