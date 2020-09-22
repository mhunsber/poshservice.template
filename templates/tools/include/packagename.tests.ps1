$scriptPath = $MyInvocation.MyCommand.Path -replace '.tests.ps1$', '.ps1'
. $scriptPath -Verbose

Describe "PoshExampleService" {
    It "defines the core loop delay" {
        Test-Path 'Variable:\MSDELAY' | Should -Be $true
        $MSDelay | Should -BeOfType int
    }
    It "defines an initialization function" {
        Test-Path 'Function:\startup' | Should -Be $true
    }
    It "defines a core loop function" {
        Test-Path 'Function:\run' | Should -Be $true
    }
    It "defines a cleanup function" {
        Test-Path 'Function:\cleanup' | Should -Be $true
    }
}

Describe "startup" {
    It "is implemented" { 
        { startup } | Should -Not -Throw
    }
    #It "sets the example message variable" {
    #    . startup
    #    Test-Path "Variable:message" | Should -Be $true
    #}
}

Describe "run" {
    BeforeEach {
        # if you define any variables in startup()
        # set their values here

        # $message = 'Example'
    }
    It "is implemented" { 
        { run } | Should -Not -Throw
    }
    #It "outputs the example message" { 
    #    run | Should -BeLike "*$message"
    #}
}

Describe "cleanup" {
    BeforeEach {
        # if you define any variables in startup()
        # or run(), set their values here

        # $message = 'Example'
    }
    It "is implemented" { 
        { cleanup } | Should -Not -Throw
    }
    #It "clears example message variable" {
    #    . cleanup
    #    $message | Should -BeNullOrEmpty
    #}
}