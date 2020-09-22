#############################################################
## This file must contain the following definitions:
##   * [int]$MSDELAY
##      - the delay after each core loop
##      - specify an amount in milliseconds
##   * function startup() { }
##      - service initialization
##      - executes once at service start
##   * function run() { }
##      - service core loop
##      - executes in a while($true) loop)
##   * function cleanup() { }
##      - service graceful shutdown
##      - runs once at service stop
##
## These functions are dot-sourced from the main script,
## therefore any variables declared in the startup() function
## will be in scope for the run() and cleanup() functions.
## Likewise, any variables declared in the run() function
## will be in scope for the cleanup() function.
#############################################################

New-Variable -Name MSDELAY -Value 1000 -Option Constant

function startup() {
    # $message = 'Hello World!'
    throw [System.NotImplementedException]::new()
}

function run() {
    # Write-Output "[$(Get-Date)] $message"
    throw [System.NotImplementedException]::new()
}

function cleanup() {
    # Clear-Variable message
    throw [System.NotImplementedException]::new()
}
