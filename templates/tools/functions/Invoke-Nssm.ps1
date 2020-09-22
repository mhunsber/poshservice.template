# This is only for fixing a whitespace issue with nssm (https://groups.google.com/g/salt-users/c/DTstUL3qHzk/m/K9YZQFG5CgAJ)
function Invoke-Nssm {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Command,
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$ArgumentList
    )
    $previousEncoding = [Console]::OutputEncoding
    [System.Console]::OutputEncoding = [System.Text.Encoding]::Unicode
    $nssm = nssm $Command @ArgumentList
    [System.Console]::OutputEncoding = $previousEncoding
    return $nssm
}
