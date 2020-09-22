BeforeAll {
    $scriptPath = $PSCommandPath -replace '.tests.ps1$', '.ps1'
    . $scriptPath -Verbose
}

Describe "Invoke-Nssm" {
    BeforeAll {
        $originalEncoding = [System.Console]::OutputEncoding
        function nssm { } # override the exe
    }
    AfterAll {
        # just in case
        [System.Console]::OutputEncoding = $originalEncoding
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
    It "sets the output encoding to Unicode when nssm is called" {
        Mock nssm { return [System.Console]::OutputEncoding }
        Invoke-Nssm -Command 'test' | Should -Be ([System.Text.Encoding]::Unicode) -Because "nssm output has erroneous whitespace characters when using other encodings"
    }
    It "resets the output encoding" {
        Invoke-Nssm -Command 'test'
        [System.Console]::OutputEncoding | Should -Be $originalEncoding -Because "it should reset the global encoding variable to avoid unpredictable behavior later"
    }
}
