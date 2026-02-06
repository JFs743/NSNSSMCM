<#
.SYNOPSIS
    NSNSSMCM: The Non-Sucking "Non-Sucking Service Manager" Congiguration Manager.

.DESCRIPTION
    This script manages NSSM (Non-Sucking Service Manager) services by allowing users to
    import, export, reset, or create new service configurations.
    It uses a JSON file (nsnssmcm.json) to store and retrieve service settings.

.PARAMETER Import
    Imports the configuration of an NSSM-managed service from a JSON file located in the
    ./<service_name>/nsnssmcm.json file and creates the service if it does not exist.
    May be called with multiple service names, a single service name, or no service name to import all
    configurations found in the current directory.

.PARAMETER Export
    Exports the configuration of an NSSM-managed service to a JSON file located in the
    ./<service_name>/nsnssmcm.json file if it does not already exist.
    May be called with multiple service names, a single service name, or no service name to export all
    existing services found in the current directory.

.PARAMETER Reset
    Resets the configuration of an NSSM-managed service by removing and recreating it from its JSON file.
    May be called with multiple service names, a single service name, or no service name to reset all
    configurations found in the current directory.

.PARAMETER Edit
    Opens the nssm configuration GUI for the specified service. Requires the service name to be specified.
    Only one service name can be specified with this parameter.
    After closing the GUI, the configuration is automatically exported to ./<service_name>/nsnssmcm.json.

.PARAMETER New
    Creates a new NSSM-managed service with the specified parameters and exports its configuration
    to ./<service_name>/nsnssmcm.json.
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
    .\nsnssmcm.ps1 -Import "MyService"
    Imports the configuration for "MyService" from its nsnssmcm.json file and creates the service
    if it doesn't exist.

.EXAMPLE
    .\nsnssmcm.ps1 -Export "MyService"
    Exports the configuration of "MyService" to its nsnssmcm.json file if it does not already exist.

.EXAMPLE
    .\nsnnssmm.ps1 -Reset "MyService"
    Resets the configuration of "MyService" by removing and recreating it from its nsnssmcm.json file.

.EXAMPLE
    .\nsnssmcm.ps1 -New -ServiceName "MyService" -ApplicationPath "C:\Path\To\App.exe" -AppParameters "-arg1 -arg2"
    Creates a new NSSM service named "MyService" with the specified application path and parameters,
    then exports its configuration to nsnssmcm.json.

.NOTES
    This script requires NSSM (Non-Sucking Service Manager) executable to be present in the same directory
    as the script.
    Ensure you have the necessary permissions to create, modify, and delete Windows services.
    The JSON configuration files (nsnssmcm.json) should be located in subdirectories named after the service.

.AUTHORS
    JFs743 and GitHub Copilot

#>
[CmdletBinding()]
param (
    # --- Import --- #
    [Parameter(Mandatory = $true, ParameterSetName = 'Import')]
    [switch]$Import,

    [Parameter(ParameterSetName = 'Import', ValueFromRemainingArguments = $true)]
    [string[]]$ImportItems,

    # --- Export --- #
    [Parameter(Mandatory = $true, ParameterSetName = 'Export')]
    [switch]$Export,

    [Parameter(ParameterSetName = 'Export', ValueFromRemainingArguments = $true)]
    [string[]]$ExportItems,

    # --- Reset --- #
    [Parameter(Mandatory = $true, ParameterSetName = 'Reset')]
    [switch]$Reset,

    [Parameter(ParameterSetName = 'Reset', ValueFromRemainingArguments = $true)]
    [string[]]$ResetItems,

    # --- Edit --- #
    [Parameter(Mandatory = $true, ParameterSetName = 'Edit')]
    [string]$Edit,

    # --- New --- #
    [Parameter(Mandatory = $true, ParameterSetName = 'New')]
    [switch]$New,

    [Parameter(Mandatory = $true, ParameterSetName = 'New')]
    [string]$ServiceName,

    [Parameter(Mandatory = $true, ParameterSetName = 'New')]
    [string]$ApplicationPath,

    [Parameter(Mandatory = $false, ParameterSetName = 'New')]
    [string]$AppParameters
)


function Export-NSNSSMCM_Config {
    param (
        [string]$Config
    )

    Write-Host "Exporting NSNSSMCM Config: $Config"

    $config_path = "./$Config/nsnssmcm.json"
    $service_name = $Config


    $windowsService = Get-Service -Name $service_name -ErrorAction SilentlyContinue

    if ($windowsService) {
        Write-Host "Creating nsnssmcm.json for existing service: $service_name"

        $config_keys = @(
            'Application',
            'AppParameters',
            'AppDirectory',
            # 'AppExit', # Skipping AppExit as it requires special handling
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
            'Start',
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
            Write-Host "Created nsnssmcm.json at $config_path"
        } catch {
            Write-Host "Failed to create nsnssmcm.json for service: $service_name."
            Write-Host ''
            Write-Host ''
            $config_content | ConvertTo-Json | Write-Host
        }
    } else {
        Write-Host "Service $service_name does not exist. Skipping export."
    }
}



function Import-NSNSSMCM_Config {
    param (
        [string]$Config
    )

    Write-Host "Importing NSNSSMCM Config: $Config"


    $config_path = Get-Item -Path "./$Config/nsnssmcm.json"
    $config_content = Get-Content -Path $config_path | ConvertFrom-Json

    $windowsService = Get-Service -Name $config_content.Name -ErrorAction SilentlyContinue

    if (-not $windowsService) {
        Write-Host "Creating service: $($config_content.Name)"

        $nssm_args = @(
            'install', $config_content.Name, $config_content.Application
        )
        & $nssm_file @nssm_args
    }

    foreach ($key in $config_content.PSObject.Properties.Name) {
        if ($key -notin @('Application', 'Name')) {
            Write-Host "Setting $key to $($config_content.$key)"
            & $nssm_file 'set', $config_content.Name, $key, $config_content.$key
        }
    }

    Write-Host "Starting service: $($config_content.Name)"
    Start-Service -Name $config_content.Name
}


function Reset-NSNSSMCM_Config {
    param (
        [string]$Config
    )

    Write-Host "Resetting NSNSSMCM Config: $Config"


    $config_path = Get-Item "$Config/nsnssmcm.json" | Select-Object -ExpandProperty FullName
    $service_name = Get-Item -Path $config_path |
        Select-Object -ExpandProperty DirectoryName |
            Split-Path -Leaf

    Write-Host "Recreating service: $service_name from $config_path"

    $nssm_args = @(
        'remove', $service_name, 'confirm'
    )
    & $nssm_file @nssm_args
    Import-NSNSSMCM_Config -Config $Config
}


function New-NSNSSMCM_Service {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,
        [Parameter(Mandatory = $true)]
        [string]$ApplicationPath,
        [Parameter(Mandatory = $false)]
        [string]$AppParameters
    )

    Write-Host "Creating new NSNSSMCM Service: $ServiceName"

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

    Export-NSNSSMCM_Config -Configs $ServiceName

    Write-Host "Starting service: $ServiceName"
    Start-Service -Name $ServiceName
}


$mode = $($PSCmdlet.ParameterSetName)

$Targets = @()

switch ($mode) {
    'Import' {
        if ($ImportItems.Count -gt 0) {
            $Targets = $ImportItems
        }
    }
    'Export' {
        if ($ExportItems.Count -gt 0) {
            $Targets = $ExportItems
        }
    }
    'Reset' {
        if ($ResetItems.Count -gt 0) {
            $Targets = $ResetItems
        }
    }
    'Edit' {
        $Targets = @($Edit)
    }
    'New' {
        $Targets = @($ServiceName)
    }
}

if ($Targets.Count -eq 0) {
    $Targets = Get-ChildItem -Directory | Select-Object -ExpandProperty Name
}


$nssm_file = Get-Item "$PSScriptroot/nssm.exe"

if ( -not $nssm_file) {
    throw "NSSM executable not found at $PSScriptroot/nssm.exe"
}

Write-Host 'NSNSSMCM: The Non-Sucking "Non-Sucking Service Manager" Configuration Manager.'

switch ($mode) {
    'Import' {
        foreach ($target in $Targets) {
            Import-NSNSSMCM_Config -Config $target
        }
    }
    'Export' {
        foreach ($target in $Targets) {
            Export-NSNSSMCM_Config -Config $target
        }
    }
    'Reset' {
        foreach ($target in $Targets) {
            Reset-NSNSSMCM_Config -Config $target
        }
    }
    'New' {
        $new_service_args = @{
            ServiceName     = $ServiceName
            ApplicationPath = $ApplicationPath
            AppParameters   = $AppParameters
            New             = $New
        }
        New-NSNSSMCM_Service @new_service_args
    }
    'Edit' {
        Write-Host "Opening NSSM GUI for service: $Edit"
        $nssm_args = @(
            'edit', $Edit
        )
        & $nssm_file @nssm_args

        Export-NSNSSMCM_Config -Config $Edit
    }

    default {
        Import-NSNSSMCM_Config
        Export-NSNSSMCM_Config
    }
}
