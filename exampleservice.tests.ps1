Describe "exampleservice" {
    BeforeAll {
        choco pack "$PSScriptRoot\poshservice.template.nuspec"
        choco upgrade poshservice.template -s .

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
                Path = '$TestDrive\logs\test.log'
                Verbose=`$true
                Rotate = @{
                    Enabled = `$true
                    Every = 'Minute'
                    KeepFiles = 30
                }
            }
        }
"@
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
            Start-Sleep -Milliseconds 250
            (Get-Service -Name exampleservice).Status | Should -Be 'Running'
        }
        It "stops" {
            $service = Get-Service -Name exampleservice
            Start-Service -InputObject $service
            Stop-Service -InputObject $service -NoWait
            $service.WaitForStatus('Stopped', '00:00:30')
            (Get-Service -Name exampleservice).Status | Should -Be 'Stopped'
        }
        It "outputs to a file" {
            Start-Service -Name exampleservice
            Start-Sleep -Milliseconds 250
            "$TestDrive\logs\test.log" | Should -Exist
        }
        It "Resumes after an update" {
            Start-Service -Name exampleservice
            (Get-Content -Path $nuspecFile -Raw) -replace '<version>1.0</version>', "<version>1.1</version>" | Out-File -FilePath $nuspecFile
            choco pack $nuspecFile
            choco upgrade exampleservice -s . -y
            Start-Sleep -Milliseconds 250
            (Get-Service -Name exampleservice).Status | Should -Be 'Running'
        }
    }
    AfterAll {
        Pop-Location
        choco uninstall poshservice.template
        $serviceController = Get-Service -Name exampleservice -ErrorAction Ignore
        if ($serviceController) {
            Stop-Service -InputObject $serviceController -NoWait
            $serviceController.WaitForStatus('Stopped', '00:00:30')
            $w32service = Get-WmiObject -Class 'win32_service' -Filter "Name='exampleservice'"
            $w32service.Delete()
        }
    }
}
