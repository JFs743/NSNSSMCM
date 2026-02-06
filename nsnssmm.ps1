<#
.SYNOPSIS
    NSNSSMM: The Non-Sucking "Non-Sucking Service Manager" Manager.

.DESCRIPTION
    This script manages NSSM (Non-Sucking Service Manager) services by allowing users to
    import, export, reset, or create new service configurations.
    It uses a JSON file (nsnssmm.json) to store and retrieve service settings.

.PARAMETER Import
    Imports the configuration of an NSSM-managed service from a JSON file located in the
    ./<service_name>/nsnssmm.json file and creates the service if it does not exist.
    May be called with multiple service names, a single service name, or no service name to import all
    configurations found in the current directory.

.PARAMETER Export
    Exports the configuration of an NSSM-managed service to a JSON file located in the
    ./<service_name>/nsnssmm.json file if it does not already exist.
    May be called with multiple service names, a single service name, or no service name to export all
    existing services found in the current directory.

.PARAMETER Reset
    Resets the configuration of an NSSM-managed service by removing and recreating it from its JSON file.
    May be called with multiple service names, a single service name, or no service name to reset all
    configurations found in the current directory.

.PARAMETER Edit
    Opens the nssm configuration GUI for the specified service. Requires the service name to be specified.
    Only one service name can be specified with this parameter.
    After closing the GUI, the configuration is automatically exported to ./<service_name>/nsnssmm.json.

.PARAMETER New
    Creates a new NSSM-managed service with the specified parameters and exports its configuration
    to ./<service_name>/nsnssmm.json.
    Requires the ServiceName and ApplicationPath parameters to be specified.

.PARAMETER ServiceName
    The name of the NSSM-managed service to create when using the New parameter.
    Required when using the "-New" parameter switch.

.PARAMETER ApplicationPath
    The path to the application executable for the NSSM-managed service to create when using the New parameter.
    Required when using the "-New" parameter switch.

.PARAMETER AppParameters
    The parameters to pass to the application executable for the NSSM-managed service to create when using
    the New parameter.
    Optional when using the "-New" parameter switch.

.EXAMPLE
    .\nsnssmm.ps1 -Import "MyService"
    Imports the configuration for "MyService" from its nsnssmm.json file and creates the service
    if it doesn't exist.

.EXAMPLE
    .\nsnssmm.ps1 -Export "MyService"
    Exports the configuration of "MyService" to its nsnssmm.json file if it does not already exist.

.EXAMPLE
    .\nsnnssmm.ps1 -Reset "MyService"
    Resets the configuration of "MyService" by removing and recreating it from its nsnssmm.json file.

.EXAMPLE
    .\nsnssmm.ps1 -New -ServiceName "MyService" -ApplicationPath "C:\Path\To\App.exe" -AppParameters "-arg1 -arg2"
    Creates a new NSSM service named "MyService" with the specified application path and parameters,
    then exports its configuration to nsnssmm.json.

.NOTES
    This script requires NSSM (Non-Sucking Service Manager) executable to be present in the same directory
    as the script.
    Ensure you have the necessary permissions to create, modify, and delete Windows services.
    The JSON configuration files (nsnssmm.json) should be located in subdirectories named after the service.

.AUTHORS
    JFs743 and GitHub Copilot

#>
[CmdletBinding()]
param (
    # mutually exclusive Import, Export and Reset flags
    [Parameter(Mandatory = $false, ParameterSetName = 'Import')]
    [string[]]$Import,

    [Parameter(Mandatory = $false, ParameterSetName = 'Export')]
    [string[]]$Export,

    [Parameter(Mandatory = $false, ParameterSetName = 'Reset')]
    [string[]]$Reset,

    [Parameter(Mandatory = $true, ParameterSetName = 'Edit')]
    [string]$Edit,

    [Parameter(Mandatory = $true, ParameterSetName = 'New')]
    [switch]$New,
    [Parameter(Mandatory = $true, ParameterSetName = 'New')]
    [string]$ServiceName,
    [Parameter(Mandatory = $true, ParameterSetName = 'New')]
    [string]$ApplicationPath,
    [Parameter(Mandatory = $false, ParameterSetName = 'New')]
    [string]$AppParameters
)

$mode = $($PSCmdlet.ParameterSetName)

$nssm_file = Get-Item "$PSScriptroot/nssm.exe"

if ( -not $nssm_file) {
    throw "NSSM executable not found at $PSScriptroot/nssm.exe"
}

Write-Host 'NSNSSMM: The Non-Sucking "Non-Sucking Service Manager" Manager.'

function Export-NSNSSMM_Config {
    param (
        [string[]]$Configs
    )

    # if $configs is an array of paths
    if ($Configs.Count -gt 1) {
        foreach ($config in $Configs) {
            Export-NSNSSMM_Config -Configs $config
        }
        return
    }
    # if $configs is empty, export all configs
    if (-not $Configs) {
        Get-ChildItem -Path './*/nsnssmm.json' -File | ForEach-Object {
            Export-NSNSSMM_Config -Configs $_.Directory.Name
        }
    }
    Write-Host "Exporting NSNSSMM Config: $Configs"

    $config_path = "./$Configs/nsnssmm.json"
    $service_name = $Configs


    $windowsService = Get-Service -Name $service_name -ErrorAction SilentlyContinue

    if ($windowsService) {
        Write-Host "Creating nsnssmm.json for existing service: $service_name"

        $config_keys = @(
            'Application',
            'AppParameters',
            'AppDirectory',
            'AppExit',
            'AppAffinity',
            'AppEnvironment',
            'AppEnvironmentExtra',
            'AppNoConsole',
            'AppPriority',
            'AppRestartDelay',
            'AppStdin',
            'AppStdinShareMode',
            'AppStdinCreationDisposition',
            'AppStdinFlagsAndAttributes',
            'AppStdout',
            'AppStdoutShareMode',
            'AppStdoutCreationDisposition',
            'AppStdoutFlagsAndAttributes',
            'AppStderr',
            'AppStderrShareMode',
            'AppStderrCreationDisposition',
            'AppStderrFlagsAndAttributes',
            'AppStopMethodSkip',
            'AppStopMethodConsole',
            'AppStopMethodWindow',
            'AppStopMethodThreads',
            'AppThrottle',
            'AppRotateFiles',
            'AppRotateOnline',
            'AppRotateSeconds',
            'AppRotateBytes',
            'AppRotateBytesHigh',
            'DependOnGroup',
            'DependOnService',
            'Description',
            'DisplayName',
            'ImagePath',
            'ObjectName',
            'Name',
            'Start-Process',
            'Type'
        )

        $config_content = [ordered]@{}
        $config_keys | ForEach-Object {
            $key = $_
            $nssm_args = @(
                'get', $service_name, $key
            )
            $value = & $nssm_file @nssm_args
            $value = $value[0].Trim()
            $value = $value -replace "(`0)+", ''
            if ($value) {
                $config_content[$key] = $value
            }
        }
        try {
            $config_content | ConvertTo-Json | Set-Content -Path $config_path -ErrorAction Stop
            Write-Host "Created nsnssmm.json at $config_path"
        } catch {
            Write-Host "Failed to create nsnssmm.json for service: $service_name."
            Write-Host ''
            Write-Host ''
            $config_content | ConvertTo-Json | Write-Host
        }
    }
}



function Import-NSNSSMM_Config {
    param (
        [string[]]$Configs
    )

    # if $configs is an array of paths
    if ($Configs.Count -gt 1) {
        foreach ($config in $Configs) {
            Import-NSNSSMM_Config -Configs $config
        }
        return
    }
    # if $configs is empty, import all configs
    if (-not $Configs) {
        $Configs = Get-Item -Path './*/nsnssmm.json' | ForEach-Object {
            Import-NSNSSMM_Config -Configs $_.Directory.Name
        }
    }
    Write-Host "Importing NSNSSMM Config: $Configs"


    $config_path = Get-Item -Path "./$Configs/nsnssmm.json"
    $config = Get-Content -Path $config_path | ConvertFrom-Json

    $windowsService = Get-Service -Name $config.Name -ErrorAction SilentlyContinue

    if (-not $windowsService) {
        Write-Host "Creating service: $($config.Name)"

        $nssm_args = @(
            'install', $config.Name, $config.Application
        )
        & $nssm_file @nssm_args
    }

    foreach ($key in $config.PSObject.Properties.Name) {
        if ($key -notin @('Application', 'Name')) {
            Write-Host "Setting $key to $($config.$key)"
            & $nssm_file 'set', $config.Name, $key, $config.$key
        }
    }

    Write-Host "Starting service: $($config.Name)"
    Start-Service -Name $config.Name
}

function Reset-NSNSSMM_Config {
    param (
        [string[]]$Configs
    )
    # if $configs is an array of paths
    if ($Configs.Count -gt 1) {
        foreach ($config in $Configs) {
            Reset-NSNSSMM_Config -Configs $config
        }
        return
    }
    # if $configs is empty, import all configs
    if (-not $Configs) {
        Get-Item -Path './*/nsnssmm.json' | ForEach-Object {
            Reset-NSNSSMM_Config -Configs $_.Directory.Name
        }
    }

    Write-Host "Resetting NSNSSMM Config: $Configs"


    $config_path = Get-Item "$Configs/nsnssmm.json" | Select-Object -ExpandProperty FullName
    $service_name = Get-Item -Path $config_path |
        Select-Object -ExpandProperty DirectoryName |
            Split-Path -Leaf

    Write-Host "Recreating service: $service_name from $config_path"

    $nssm_args = @(
        'remove', $service_name, 'confirm'
    )
    & $nssm_file @nssm_args
    Import-NSNSSMM_Config -Config $Configs
}

function New-NSNSSMM_Service {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,
        [Parameter(Mandatory = $true)]
        [string]$ApplicationPath,
        [Parameter(Mandatory = $false)]
        [string]$AppParameters
    )

    Write-Host "Creating new NSNSSMM Service: $ServiceName"

    $AppDirectory = Split-Path -Path "./$ServiceName/" -Resolve

    $nssm_args = @(
        'install', $ServiceName, $ApplicationPath
    )

    if ($AppParameters) {
        $nssm_args += $AppParameters
    }

    & $nssm_file @nssm_args

    if ($AppDirectory) {
        $nssm_args = @(
            'set', 'AppDirectory', $AppDirectory
        )
        & $nssm_file @nssm_args
    }

    Export-NSNSSMM_Config -Configs $ServiceName

    Write-Host "Starting service: $ServiceName"
    Start-Service -Name $ServiceName
}

$configs = @()
$configs += $Import
$configs += $Export
$configs += $Reset

Write-Host "NSNSSMM Mode: $mode"
Write-Host '-----------------------------------'
Write-Host "Configs: $configs"


switch ($mode) {
    'Import' {
        Import-NSNSSMM_Config -Configs $Import
    }
    'Export' {
        Export-NSNSSMM_Config -Configs $Export
    }
    'Reset' {
        Reset-NSNSSMM_Config -Configs $Reset
    }
    'New' {
        $new_service_args = @{
            ServiceName     = $ServiceName
            ApplicationPath = $ApplicationPath
            AppParameters   = $AppParameters
            New             = $New
        }
        New-NSNSSMM_Service @new_service_args
    }
    'Edit' {
        Write-Host "Opening NSSM GUI for service: $Edit"
        $nssm_args = @(
            'edit', $Edit
        )
        & $nssm_file @nssm_args

            Export-NSNSSMM_Config -Configs $Edit
    }

    default {
        Import-NSNSSMM_Config
        Export-NSNSSMM_Config
    }
}
