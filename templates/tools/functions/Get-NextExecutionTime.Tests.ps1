BeforeAll {
    $scriptPath = $PSCommandPath -replace '.tests.ps1$', '.ps1'
    . $scriptPath -Verbose
}
Describe "Get-NextExecutionTime" {
    BeforeAll {
        Mock Get-Date {
            if($null -eq $Year) { $Year = 2020 }
            if($null -eq $Month) { $Month = 9 }
            if($null -eq $Day) { $Day = 18 }
            if($null -eq $Hour) { $Hour = 12 }
            if($null -eq $Minute) { $Minute = 45 }
            if($null -eq $Second) { $Second = 55 }
            if($null -eq $Millisecond) { $Millisecond = 12 }
            return [datetime]::new($Year,$Month,$Day,$Hour,$Minute,$Second,$Millisecond,'Utc')
        } -RemoveParameterType Year,Month,Day,Hour,Minute,Second,Millisecond
    }
    It "Returns the start of the next <RepetitionInterval> when RepetitionInterval is <RepetitionInterval>" -TestCases @(
        @{ RepetitionInterval='Minute'; Expected=([datetime]'2020-09-18T12:46:00.000Z').ToUniversalTime() },
        @{ RepetitionInterval='Hour'; Expected=([datetime]'2020-09-18T13:00:00.000Z').ToUniversalTime() },
        @{ RepetitionInterval='Day'; Expected=([datetime]'2020-09-19T00:00:00.000Z').ToUniversalTime() },
        @{ RepetitionInterval='Week'; Expected=([datetime]'2020-09-20T00:00:00.000Z').ToUniversalTime() }
    ) { param($RepetitionInterval,$Expected)
        Get-NextExecutionTime -RepetitionInterval $RepetitionInterval | Should -Be $Expected
    }
}
