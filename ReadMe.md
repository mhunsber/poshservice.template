# PowerShell Service Chocolatey Package

## Summary

This sets up a template for executing a PowerShell script as a simple background windows service.
It uses nssm (<https://nssm.cc/usage>) for installing and managing the service.
Nssm allows I/O Redirection, so any values that would get printed to the console get logged to a file.

## Use Case

Sometimes you want to be able to write a quick windows service using the PowerShell scripting language. This makes it easy to quickly edit and test the service on any system without having to set up a development environment. It also streamlines the service installation process by using nssm.

Since this runs within the PowerShell interpreter, this should be used for tasks that are either proof of concept or do not require a lot of performance, such as system monitoring.

## Requirements

This is a chocolatey template and requires that you have chocolatey installed. <https://chocolatey.org/install>

## Getting Started

1. Clone this repository locally.
1. Use chocolatey to package the template: `choco pack .\path\to\poshservice.template.nuspec`
1. Use chocolatey to install the template: `choco install poshservice.template -y`.
1. Create a new chocolatey package with the template: `choco new mynewposhservice -t poshservice`.
1. Follow the Quick Start steps in `mynewposhservice/readme.md`.

## How it Works

The chocolatey install script uses nssm to install a new windows service that runs the `startservice.ps1` script. Nssm passes in some service environment variables. If log rotation is enabled, the `startservice.ps1` script kicks off a background job that periodically rotates and deletes the I/O redirected log files. It then runs a loop that, when nssm tells the service to stop, will break out into the finally block where it can run any cleanup work needed for a graceful stop.

## Tests

Tests are written using the Pester module.
You can learn how to install Pester here: <https://pester.dev/docs/introduction/installation>
