function Reset-NssmServiceLogs {
    param(
        [string]$ServiceName,
        [string]$RepetitionInterval,
        [int]$MaxLogFiles
    )
    Write-Output "Starting log rotation"
    try {
        $logFilePath = Invoke-Nssm get $ServiceName appstdout -ErrorAction Continue 2>$null
        $basePath = [System.IO.Path]::GetDirectoryName($logFilePath)
        $extension = [System.IO.Path]::GetExtension($logFilePath)
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($logFilePath)
        do {
            $now = [datetime]::Now
            $nextExec = Get-NextExecutionTime -RepetitionInterval $RepetitionInterval
            Write-Output "Next log rotation at $nextExec"
            $sleepTime = (New-TimeSpan -Start $now -End $nextExec).TotalSeconds

            Start-Sleep -Seconds ([math]::Max(0, [int]$sleepTime))
            Write-Output (Invoke-Nssm rotate $ServiceName -ErrorAction Continue 2>$null)
            # give some time for rotation to complete
            # otherwise there's a chance we have n+1 log files
            # or immediately run the loop again due to rounding
            Start-Sleep -Seconds 2 

            Get-ChildItem -Path $basePath -Filter "$filename-*$extension" | `
                Sort-Object -Property LastWriteTime -Descending | `
                Select-Object -Skip $MaxLogFiles | Foreach-Object {
                    Write-Output "Removing $($_.FullName)"
                    Remove-Item -Path $_.FullName
                }
        } while ($nextExec -gt $now) # this is always true, but lets us hack the loop for tests
    } finally {
        Write-Output "Ending log rotation."
    }
}
