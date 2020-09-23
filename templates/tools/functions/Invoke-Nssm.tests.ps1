BeforeAll {
    $scriptPath = $PSCommandPath -replace '.tests.ps1$', '.ps1'
    . $scriptPath -Verbose
}

Describe "Invoke-Nssm" -Skip:($null -eq (Get-Command -Name nssm.exe -CommandType Application -ErrorAction Ignore)) {
    BeforeAll {
        Invoke-Nssm -Command 'install' 'testservice' 'powershell.exe' -ErrorAction Stop
    }
    AfterAll {
        $svc = Get-WmiObject -Class 'win32_service' -Filter "Name='testservice'"
        if ($svc) {
            $svc.Delete()
        }
    }
    It "can register a new service" {
        (Get-Service -Name testservice -ErrorAction Ignore) | Should -Not -BeNullOrEmpty
    }
    It "can get service properties" {
        Invoke-Nssm -Command 'get' 'testservice' 'application' | Should -Be 'powershell.exe'
    }
    It "can set service properties" {
        Invoke-Nssm -Command 'set' 'testservice' 'appdirectory' 'C:\directory with\spaces'
        Invoke-Nssm -Command 'get' 'testservice' 'appdirectory' | Should -Be 'C:\directory with\spaces'
    }
    It 'can remove the service' {
        Invoke-Nssm -Command 'remove' 'testservice' 'confirm'
        (Get-Service -Name testservice -ErrorAction Ignore) | Should -BeNullOrEmpty
    }
}
