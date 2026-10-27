<#
.SYNOPSIS
    Deploys the Foundry project at subscription scope into the CURRENT Azure CLI
    subscription context.

.DESCRIPTION
    Uses the subscription currently selected in Azure CLI
    (set beforehand with: az account set --subscription <id>).
    Runs a what-if preview, asks for confirmation, then deploys.

.PARAMETER Location
    Azure region for the deployment and resources. Default: eastus2.

.PARAMETER ParamFile
    Bicep parameter file. Default: main.bicepparam.

.PARAMETER Force
    Skip the confirmation prompt (useful in pipelines).

.EXAMPLE
    .\deploy.ps1
    .\deploy.ps1 -Location centralus -ParamFile prod.bicepparam
#>
[CmdletBinding()]
param(
    [string]$Location = 'eastus2',
    [string]$ParamFile = 'main.bicepparam',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

# Verify Azure CLI is available and logged in
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    throw "Azure CLI not found. Install it from https://aka.ms/installazurecliwindows"
}

$account = az account show -o json 2>$null | ConvertFrom-Json
if (-not $account) {
    throw "Not logged in. Run 'az login' first."
}

$subscriptionId   = $account.id
$subscriptionName = $account.name
$deploymentName   = "foundry-$(Get-Date -Format 'yyyyMMddHHmmss')"

Write-Host "Using subscription: $subscriptionName ($subscriptionId)" -ForegroundColor Cyan

$deployArgs = @(
    '--name', $deploymentName,
    '--location', $Location,
    '--template-file', 'main.bicep',
    '--parameters', $ParamFile,
    '--parameters', "subscriptionId=$subscriptionId", "location=$Location"
)

Write-Host "Running what-if..." -ForegroundColor Cyan
az deployment sub what-if @deployArgs
if ($LASTEXITCODE -ne 0) { throw "What-if failed." }

if (-not $Force) {
    $confirm = Read-Host "Deploy to '$subscriptionName'? (y/N)"
    if ($confirm -notmatch '^[Yy]$') {
        Write-Host "Cancelled."
        return
    }
}

Write-Host "Deploying..." -ForegroundColor Cyan
az deployment sub create @deployArgs --query properties.outputs -o jsonc
if ($LASTEXITCODE -ne 0) { throw "Deployment failed." }

Write-Host "Deployment complete." -ForegroundColor Green
