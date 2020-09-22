function Get-NextExecutionTime {
    param(
        [string]$RepetitionInterval
    )
    switch($RepetitionInterval) {
        'Minute' {
            return (Get-Date -Second 0 -Millisecond 0).AddMinutes(1)
        }
        'Hour' {
            return (Get-Date -Minute 0 -Second 0 -Millisecond 0).AddHours(1)
        }
        'Day' {
            return (Get-Date -Hour 0 -Minute 0 -Second 0 -Millisecond 0).AddDays(1)
        }
        'Week' {
            return (Get-Date -Hour 0 -Minute 0 -Second 0 -Millisecond 0).AddDays(7 - (Get-Date).DayOfWeek)
        }
        default {
            Write-Warning -Message "Expected RepetitionInterval to be one of 'Minute|Hour|Day|Week', but was '$_'. Using default interval."
            return (Get-Date -Hour 0 -Minute 0 -Second 0 -Millisecond 0).AddDays(1)
        }
    }
}