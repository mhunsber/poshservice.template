Describe "exampleservice" {
    BeforeAll {
        if(!(Test-Path -Path "$PSScriptRoot\poshservice.template.*.nupkg")) {
            choco pack "$PSScriptRoot\poshservice.template.nuspec"
        }
        choco install poshservice.template -s .

        Push-Location -Path "TestDrive:\"
        choco new exampleservice -t poshservice --version 1.0
        $nuspecFile = '.\exampleservice\exampleservice.nuspec'
        (Get-Content -Path $nuspecFile -Raw) -replace '__REPLACE__', "test" | Out-File -FilePath $nuspecFile
        Set-Content -Path '.\exampleservice\tools\include\packagename.ps1' -Value @"
            New-Variable -Name MSDELAY -Value 1000 -Option Constant

            function startup() {
                `$message = 'Hello World!'
            }
            
            function run() {
                Write-Output "[`$(Get-Date)] `$message"
            }
            
            function cleanup() {
                Clear-Variable message
            }
"@
        Set-Content -Path '.\exampleservice\tools\startservice.psd1' -Value @"
        @{
            Name = ''
            DisplayName = 'Example Service'
            Description = 'The Description'
            RunAs = 'LOCALSERVICE'
            Startup = 'SERVICE_DELAYED_AUTO_START' # SERVICE_AUTO_START|SERVICE_DELAYED_AUTO_START|SERVICE_DEMAND_START|SERVICE_DISABLED
            ShutdownTimeout = 5000
            Logging = @{
                Path = 'C:\exampleservice\logs\test.log'
                Verbose=`$true
                Rotate = @{
                    Enabled = `$true
                    Every = 'Minute'
                    KeepFiles = 30
                }
            }
        }
"@
        # I don't like that we have to do this, but appveyor does not let you set the console output, so we have to change very the scripts we're testing
        (Get-Content -Path '.\exampleservice\tools\chocolateyInstall.ps1' -Raw) `
            -replace '.+console\]::OutputEncoding\s?=.+', '#$0' ` # remove any output encoding assignment
            -replace 'nssm get .+ objectname', '"NT Authority\LocalService"' | ` # fake out the runas result
            Out-File -FilePath '.\exampleservice\tools\chocolateyInstall.ps1'
        (Get-Content -Path '.\exampleservice\tools\chocolateyUninstall.ps1' -Raw) `
            -replace '.+console\]::OutputEncoding\s?=.+', '#$0' `
            -replace 'nssm get .+ objectname', '"NT Authority\LocalService"' | `
            Out-File -FilePath '.\exampleservice\tools\chocolateyUninstall.ps1'

        choco pack $nuspecFile
    }
    Describe "chocolateyInstall" {
        BeforeAll {
            choco install exampleservice -s . -y
            $svc = Get-WmiObject -Class 'Win32_Service' -Filter "Name='exampleservice'"
        }
        AfterAll {
            choco uninstall exampleservice -y
        }
        It "registers the service" {
            $svc | Should -Not -BeNullOrEmpty
        }
        It "sets the service display name" {
            $svc.DisplayName | Should -Be "Example Service"
        }
        It "sets the service description" {
            $svc.Description | Should -Be "The Description"
        }
        It "sets the user context" {
            $svc.StartName | Should -BeLike '*LocalService'
        }
        It "sets the start mode" {
            $svc.StartMode | Should -Be 'Auto'
            (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\exampleservice').DelayedAutoStart | Should -Be 1
        }
    }
    Describe "chocolateyUninstall" {
        BeforeAll {
            choco install exampleservice -s . -y
        }
        It "removes the service" {
            choco uninstall exampleservice -y
            (Get-Service -Name exampleservice -ErrorAction Ignore) | Should -BeNullOrEmpty
        }
    }
    Describe "the service" {
        BeforeAll {
            choco install exampleservice -s . -y
        }
        AfterAll {
            choco uninstall exampleservice -y
        }
        It "starts" {
            { Start-Service -Name exampleservice } | Should -Not -Throw
            Start-Sleep -Seconds 1
            (Get-Service -Name exampleservice).Status | Should -Be 'Running'
        }
        It "stops" {
            Start-Service -Name exampleservice
            { Stop-Service -Name exampleservice } | Should -Not -Throw
            Start-Sleep -Seconds 1
            (Get-Service -Name exampleservice).Status | Should -Be 'Stopped'
        }
        It "outputs to a file" {
            Start-Service -Name exampleservice
            Start-Sleep -Seconds 1
            'C:\exampleservice\logs\test.log' | Should -Exist
        }
        It "Resumes after an update" {
            Start-Service -Name exampleservice
            (Get-Content -Path $nuspecFile -Raw) -replace '<version>1.0</version>', "<version>1.1</version>" | Out-File -FilePath $nuspecFile
            choco pack $nuspecFile
            choco upgrade exampleservice -s . -y
            Start-Sleep -Seconds 1
            (Get-Service -Name exampleservice).Status | Should -Be 'Running'
        }
    }
    AfterAll {
        Pop-Location
        choco uninstall poshservice.template
        $service = Get-WmiObject -Class 'win32_service' -Filter "Name='exampleservice'"
        if ($service) {
            $service.StopService()
            $service.Delete()
        }
    }
}
