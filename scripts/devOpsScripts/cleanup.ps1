<#
.SYNOPSIS
    Cleans up the Azure resources for the Field Engineer application for a given azd environment.

    Assumes you have already run `Connect-AzAccount`
    Requires `Az` module:
        Install-Module -Name Az
        Import-Module -Name Az
.DESCRIPTION
    There are times that azd down doesn't work well.  At time of writing, this includes complex
    environments with multiple resource groups and networking.  To remedy this, this script removes
    the Azure resources in the correct order.

    If you do not provide any parameters, this script will clean up the most current azd environment.
.PARAMETER Prefix
    The prefix of the Azure environment to clean up.  Provide this OR the ResourceGroup parameter to
    clean up a specific environment. If your group name was `rg-prosegh112v1-terraform` then the
    Prefix parameter should be set as `rg-prosegh112v1`.
.PARAMETER WhatIf
    Use the -WhatIf parameter to see what changes would be applied. Defaults to false.
.PARAMETER NoPrompt
    If included, do not prompt for confirmation.
.PARAMETER AsJob
    Use The -AsJob parameter to delete the resource groups in the background.
.EXAMPLE
    .\cleanup.ps1 -Prefix "rg-prosegh112v1" -WhatIf
    This example will show what changes would be applied if the script were to run with the given parameters.
    
    .\cleanup.ps1 -Prefix "rg-prosegh112v1" -AsJob
    This example will ask for confirmation, remove resources, and then run asynchronously for a quick cleanup.
#>

Param(
    [Parameter(Mandatory = $false)][string]$Prefix,
    [switch]$WhatIf,
    [switch]$NoPrompt = $false,
    [switch]$AsJob = $false
)

# Default Settings
$CleanupAzureDirectory = $false
$rgPrefix = ""
$rgTerraformState = ""
$rgPrimaryApp = ""
$rgSecondaryApp = ""
$rgDatabase = ""
$rgFrontDoor = ""
$tagKey = "app-pattern-name"
$tagValue = "java-rwa"

function Test-ResourceGroupExists($resourceGroupName) {
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    return $null -ne $resourceGroup
}

function Test-ResourceGroupIsAppPatterns($resourceGroupName) {
    if (Test-ResourceGroupExists -ResourceGroupName $resourceGroupName) {
        $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
        # only well-known groups should be deleted
        return $resourceGroup.Tags -and $resourceGroup.Tags.ContainsKey($tagKey) -and $resourceGroup.Tags[$tagKey] -eq $tagValue
    }
    else {
        return $false
    }
}

function Remove-DiagnosticSettingsForResourceGroup($resourceGroupName) {
    Get-AzResource -ResourceGroupName $resourceGroupName
    | Foreach-Object {
        $resourceName = $_.Name
        $resourceId = $_.ResourceId
        Get-AzDiagnosticSetting -ResourceId $resourceId -ErrorAction SilentlyContinue | Foreach-Object {
            if ($WhatIf) {
                "`tDiagnostic $resourceGroupName::$resourceName::$($_.Name) would be deleted" | Write-Host
            } else {
                "`tRemoving $resourceGroupName::$resourceName::$($_.Name)" | Write-Output
                Remove-AzDiagnosticSetting -ResourceId $resourceId -Name $_.Name 
            }
        }
    }
}

function Remove-ResourceGroupFromAzure($resourceGroupName, $asJob) {
    if (Test-ResourceGroupIsAppPatterns -ResourceGroupName $resourceGroupName) {
        if ($WhatIf) {
            "`tResource Group $resourceGroupName would be deleted" | Write-Host
        } else {
            "`tRemoving: $resourceGroupName" | Write-Output
            if ($asJob) {
                Remove-AzResourceGroup -Name $resourceGroupName -Force -AsJob
            } else {
                Remove-AzResourceGroup -Name $resourceGroupName -Force
            }
        }
    }
}

function Get-AppPatternsEnvironment($resourceGroupName) {
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
    if ($resourceGroup.Tags.ContainsKey($tagKey)) {
        return $resourceGroup.Tags['environment']
    } else {
        return "dev"
    }
}

function Remove-PrivateEndpointsForResourceGroup($resourceGroupName) {
    Get-AzPrivateEndpoint -ResourceGroupName $resourceGroupName
    | Foreach-Object {
        if ($WhatIf) {
            "`tPrivate Endpoint $resourceGroupName would be deleted" | Write-Host
        } else {
            "`tRemoving $resourceGroupName::$($_.Name)" | Write-Output
            Remove-AzPrivateEndpoint -Name $_.Name -ResourceGroupName $_.ResourceGroupName -Force
        }
    }
}

if ($Prefix) {
    $rgPrefix = $Prefix
    $rgTerraformState = "$rgPrefix-terraform"
    
    $appPatternsEnvironment = Get-AppPatternsEnvironment -ResourceGroupName $rgTerraformState

    $rgPrimaryApp = "$rgPrefix-app1-$appPatternsEnvironment"
    $rgSecondaryApp = "$rgPrefix-app2-$appPatternsEnvironment"
    $rgDatabase = "$rgPrefix-db-$appPatternsEnvironment"
    $rgFrontDoor = "$rgPrefix-fd-$appPatternsEnvironment"
} else {
    Write-Host  "No prefix information provided - cannot clean up" -ForegroundColor Red
    exit 1
}

"`nCleaning up environment for workload" | Write-Output

# Get the list of resource groups to deal with
$resourceGroups = [System.Collections.ArrayList]@()
if (Test-ResourceGroupIsAppPatterns -ResourceGroupName $rgFrontDoor) {
    "`tFound FrontDoor resource group: $rgFrontDoor" | Write-Output
    $resourceGroups.Add($rgFrontDoor) | Out-Null
}
if (Test-ResourceGroupIsAppPatterns -ResourceGroupName $rgPrimaryApp) {
    "`tFound PrimaryApp resource group: $rgPrimaryApp" | Write-Output
    $resourceGroups.Add($rgPrimaryApp) | Out-Null
}
if (Test-ResourceGroupIsAppPatterns -ResourceGroupName $rgSecondaryApp) {
    "`tFound SecondaryApp resource group: $rgSecondaryApp" | Write-Output
    $resourceGroups.Add($rgSecondaryApp) | Out-Null
}
if (Test-ResourceGroupIsAppPatterns -ResourceGroupName $rgDatabase) {
    "`tFound Database resource group: $rgDatabase" | Write-Output
    $resourceGroups.Add($rgDatabase) | Out-Null
}
if (Test-ResourceGroupIsAppPatterns -ResourceGroupName $rgTerraformState) {
    "`tFound TerraformState resource group: $rgTerraformState" | Write-Output
    $resourceGroups.Add($rgTerraformState) | Out-Null
}

if ($WhatIf -eq $false -and $NoPrompt -eq $false) {
    $confirmation = Read-Host "Are you sure you want to continue? (Y/N)"
    if ($confirmation -ne "Y" -and $confirmation -ne "y") {
        # Exit the script or perform any desired action
        "Script execution aborted." | Write-Output -ForegroundColor Red
        Exit
    }
}

"`nRemoving resources from resource groups..." | Write-Output

"> Diagnostic Settings:" | Write-Output
foreach ($resourceGroupName in $resourceGroups) {
    Remove-DiagnosticSettingsForResourceGroup -ResourceGroupName $resourceGroupName
}

"> Private Endpoints:" | Write-Output
foreach ($resourceGroupName in $resourceGroups) {
    Remove-PrivateEndpointsForResourceGroup -ResourceGroupName $resourceGroupName
}

"> Resource groups:" | Write-Output
Remove-ResourceGroupFromAzure -ResourceGroupName $rgFrontDoor -AsJob:$AsJob
Remove-ResourceGroupFromAzure -ResourceGroupName $rgPrimaryApp -AsJob:$AsJob
Remove-ResourceGroupFromAzure -ResourceGroupName $rgSecondaryApp -AsJob:$AsJob
Remove-ResourceGroupFromAzure -ResourceGroupName $rgDatabase -AsJob:$AsJob
Remove-ResourceGroupFromAzure -ResourceGroupName $rgTerraformState -AsJob:$AsJob

if ($CleanupAzureDirectory -eq $true -and (Test-Path -Path ./.azure -PathType Container)) {
    "Cleaning up Azure Developer CLI state files." | Write-Output
    Remove-Item -Path ./.azure -Recurse -Force
}

"`nCleanup complete." | Write-Output