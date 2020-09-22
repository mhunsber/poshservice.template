BeforeAll {
    $scriptPath = $PSCommandPath -replace '.tests.ps1$', '.ps1'
    . $scriptPath -Verbose
}

Describe "Invoke-Nssm" {
    BeforeAll {
        Mock Get-ConsoleEncoding { return 'default' }
        Mock Set-ConsoleEncoding { }
        function nssm { } # override the exe
    }
    It "calls nssm" {
        Mock nssm {} -Verifiable
        Invoke-Nssm -Command 'help'
        Assert-VerifiableMock
    }
    It "calls nssm [command]" {
        Mock nssm -ParameterFilter { $args[0] -eq 'help' } -Verifiable
        Invoke-Nssm -Command 'help'
        Assert-VerifiableMock
    }
    It "calls nssm with extra arguments" {
        Mock nssm -Verifiable -ParameterFilter { $args[1] -eq 'test 1' -and $args[2] -eq 'test 2' -and $args[3] -eq 'test 3'}
        Invoke-Nssm 'help' 'test 1' 'test 2' 'test 3'
        Assert-VerifiableMock
    }
    It "returns the result of the nssm command" {
        Mock nssm { return 'test output' }
        Invoke-Nssm 'test' | Should -Be 'test output'
    }
    It "sets the output encoding to Unicode to prevent extra whitespace in the result" {
        Invoke-Nssm -Command 'test'
        Assert-MockCalled -CommandName Set-ConsoleEncoding -ParameterFilter { $Encoding -eq [System.Text.Encoding]::Unicode }
    }
    It "resets the output encoding to the default" {
        Invoke-Nssm -Command 'test'
        Assert-MockCalled -CommandName Set-ConsoleEncoding -ParameterFilter { $Encoding -eq 'default' }
    }
}
