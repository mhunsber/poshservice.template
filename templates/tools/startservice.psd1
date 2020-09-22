###############################################################
## This file is used for installing the service only
## To make changes to service behavior after install
## Either edit the service with nssm edit <servicename>
## or reinstall the service after modifying this file.
###############################################################
@{
    ## Service Name (defaults to chocolatey id)
    Name = ''

    ## Service Display Name (defaults to chocolatey title)
    DisplayName = ''

    ## Service Description
    Description = ''

    ## What user context to run the service under
    ## To run as a builtin account, use one of the following:
    ##      LOCALSYSTEM|NETWORKSERVICE|LOCALSERVICE
    ## To run as a specific user, set this to:
    ##      <domain>\<username>
    ##   if it is a local account, then <domain> is '.'
    ##   you will be prompted for the password
    RunAs = 'LOCALSERVICE'

    ## Service Startup Type
    ## Delayed start is preferred to automatic start since a POSH service should not be so critical that it needs to be running before other services are ready.
    Startup = 'SERVICE_DELAYED_AUTO_START' # SERVICE_AUTO_START|SERVICE_DELAYED_AUTO_START|SERVICE_DEMAND_START|SERVICE_DISABLED

    ## Time (in milliseconds) to wait after issuing ctrl-c command before forcefully closing the service.
    ## increase this if your service needs a long time to perform a graceful shutdown.
    ShutdownTimeout = 5000

    Logging = @{
        ## Logging Path (defaults to %ProgramData%\PoSHServices\<servicename>\<servicename>.log)
        ## Can be relative or absolute. You can change this after install by editing the I/O Redirection nssm settings.
        Path = ''

        ## Verbose Output (true sets VerbosePreference to 'Continue')
        Verbose=$true

        Rotate = @{
            ## Enable Rotation
            Enabled = $true

            ## Rotation Frequency (valid values are 'Minute', 'Hour', 'Day', or 'Week')
            Every = 'Day'

            ## How many log files to keep
            KeepFiles = 30
        }
    }

}