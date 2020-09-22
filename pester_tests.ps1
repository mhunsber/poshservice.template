$testResultsFile = "PesterResults.xml"
$PesterConfiguration = [PesterConfiguration]@{
    Run = @{
        ExcludePath = "$PSScriptRoot\templates\tools\include\packagename.tests.ps1"
        PassThru = $true
        Exit = $true
    }
    CodeCoverage = @{
        Enabled = $false
    }
    TestResult = @{
        Enabled = $true
        OutputFormat = 'NUnit2.5'
        OutputPath = $testResultsFile
    }

}
$res = Invoke-Pester -Configuration $PesterConfiguration
if ($env:APPVEYOR_JOB_ID) {
    (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path $testResultsFile))
}
if ($res.FailedCount -gt 0) {
    throw "$($res.FailedCount) tests failed."
}
