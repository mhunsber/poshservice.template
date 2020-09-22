BeforeAll {
    $scriptPath = $PSCommandPath -replace '.tests.ps1$', '.ps1'
    . $scriptPath -Verbose
    # import the other functions
    . "$PSScriptRoot\Get-NextExecutionTime.ps1" -Verbose
    . "$PSScriptRoot\Invoke-Nssm.ps1" -Verbose
}

Describe "Reset-NssmServiceLogs" {
    BeforeAll {
        Mock Invoke-Nssm { return 'TestDrive:\logs\test.log' } -ParameterFilter { $Command -eq 'get' }
        Mock Invoke-Nssm { return "$($ArgumentList[0]): ROTATE: The operation completed successfully."} -ParameterFilter { $Command -eq 'rotate' }
        Mock Get-NextExecutionTime { return [datetime]::Now.AddDays(-7) }
        Mock Start-Sleep { }
    }
    BeforeEach {
        New-Item -Path "TestDrive:\logs\test.log" -ItemType File -Value "temp current" -Force
        1..25 | Foreach-Object {
            $lastWriteTime = (Get-Date -Minute $_)
            $item = New-Item -Path "TestDrive:\logs\test-$_-rotated.log" -ItemType File -Value "temp file $_" -Force
            $item.LastWriteTime = $lastWriteTime
        }
    }
    It "Uses the rotate command from nssm" {
        Reset-NssmServiceLogs -ServiceName 'test' -RepetitionInterval 'Hour' -MaxLogFiles 5
        Assert-MockCalled Invoke-Nssm -ParameterFilter { $Command -eq 'rotate' }
        Assert-MockCalled Invoke-Nssm -ParameterFilter { $ArgumentList[0] -eq 'test' }
    }
    It "Clears out old logs" {
        Reset-NssmServiceLogs -ServiceName 'test' -RepetitionInterval 'Hour' -MaxLogFiles 5
        1..20 | Foreach-Object {
            "TestDrive:\logs\test-$_-rotated.log" | Should -Not -Exist
        }
    }
    It "Keeps current logs" {
        Reset-NssmServiceLogs -ServiceName 'test' -RepetitionInterval 'Hour' -MaxLogFiles 5
        "TestDrive:\logs\test.log" | Should -Exist
        21..25 | Foreach-Object {
            "TestDrive:\logs\test-$_-rotated.log" | Should -Exist
        }
    }
}
