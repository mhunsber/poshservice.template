# This is only for fixing a whitespace issue with nssm (https://groups.google.com/g/salt-users/c/DTstUL3qHzk/m/K9YZQFG5CgAJ)

function Get-ConsoleEncoding {
    return [System.Console]::OutputEncoding
}

function Set-ConsoleEncoding($Encoding) {
    [System.Console]::OutputEncoding = $Encoding
}

function Invoke-Nssm {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Command,
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$ArgumentList
    )
    $previousEncoding = Get-ConsoleEncoding
    Set-ConsoleEncoding -Encoding ([System.Text.Encoding]::Unicode)
    $nssm = nssm $Command @ArgumentList
    Set-ConsoleEncoding $previousEncoding
    return $nssm
}
