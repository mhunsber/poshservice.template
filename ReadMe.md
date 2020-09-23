# PowerShell Service Chocolatey Package

[![build status](https://ci.appveyor.com/api/projects/status/github/mhunsber/poshservice.template?svg=true)](https://ci.appveyor.com/project/mhunsber/poshservice.template)

## Summary

This sets up a template for executing a PowerShell script as a simple background windows service.
Packages created from this template use nssm (<https://nssm.cc/usage>) to install and manage the service.

## Use Case

Sometimes you want to be able to write a quick windows service using the PowerShell scripting language. This makes it easy to quickly edit and test the service on any system without having to set up a development environment. It also streamlines the service installation process by using nssm.

Since this runs within the PowerShell interpreter, this should be used for tasks that are either proof of concept or do not require a lot of performance, such as system monitoring.

## Requirements

This is a chocolatey template and requires that you have chocolatey installed. <https://chocolatey.org/install>

Packages created from the template require the latest stable version of nssm (2.24.0).
The prerelease version (2.24.101) of nssm gets stuck during shutdown when online file rotation is enabled.

## Getting Started

1. Clone this repository locally.
1. Use chocolatey to package the template: `choco pack .\path\to\poshservice.template.nuspec`
1. Use chocolatey to install the template: `choco install poshservice.template -y`.
1. Create a new chocolatey package with the template: `choco new mynewposhservice -t poshservice`.
1. Follow the Quick Start steps in `mynewposhservice\readme.md`.

## Detailed Summary

Packages created from this template use nssm the install and configure a windows service that executes a powershell script.
The script runs a loop that will break into a shutdown block when it receives a stop command so that it can handle a graceful shutdown.
Since nssm allows I/O Redirection, any messages that would get printed to the console by the script will get appended to a file.
If log rotation is enabled, the script kicks off a background job that will a) periodically tell nssm to rotate the logs while it is running, and b) delete old log files.

## Tests

Tests are written using the Pester module.
You can learn how to install Pester here: <https://pester.dev/docs/introduction/installation>
