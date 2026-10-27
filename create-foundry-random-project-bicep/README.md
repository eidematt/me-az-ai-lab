# Azure AI Foundry Random Project Deployment

This project provisions a new Azure AI Foundry resource and project in a newly created resource group with a randomized suffix. It is designed for repeatable, environment-specific deployments that keep names unique while staying easy to customize.

## What this deploys

The Bicep template creates:

- A new resource group at subscription scope
- An Azure AI Foundry (Azure AI Services) account
- A Foundry project inside that account
- Optional model deployment if `deployModel` is enabled
- Optional RBAC assignment for a user, group, or service principal on the project
- Standard tags and resource naming based on workload, environment, and region

## Repository contents

- `main.bicep` – subscription-scoped entry point for the deployment
- `main.bicepparam` – sample parameter values for a dev environment
- `deploy.ps1` – PowerShell deployment helper
- `modules/workload.bicep` – deployment logic for the resource group and Foundry resources

## Prerequisites

Before deploying, make sure you have:

- Azure CLI installed
- PowerShell
- An active Azure subscription with permission to create resource groups and Azure AI resources
- Access to a region that supports the Azure AI Foundry resources and any model you plan to deploy
- Logged in with `az login`

## Deploy with PowerShell

The script deploys to the subscription currently selected in Azure CLI. Sign in, optionally select the target subscription, then run the script from the repository directory:

```powershell
az login
az account set --subscription "<subscription-id-or-name>"
.\deploy.ps1 -Location eastus2
```

The script uses `main.bicepparam`, runs a `what-if` preview, and asks for confirmation before deploying. To use another parameter file or skip the confirmation prompt:

```powershell
.\deploy.ps1 -Location centralus -ParamFile prod.bicepparam
.\deploy.ps1 -Location eastus2 -Force
```

## Customizing the deployment

Edit `main.bicepparam` to change defaults such as:

- workload name
- environment (`dev`, `test`, or `prod`)
- Azure region
- model settings
- public network access and local auth behavior
- optional RBAC assignment for the project

Example settings from the template:

```bicep
param workload = 'aiapp'
param environment = 'dev'
param location = 'eastus2'
param publicNetworkAccess = 'Enabled'
param disableLocalAuth = true
param deployModel = false
```

To keep the same resource group across repeated runs, set a fixed value for `randomSeed`:

```bicep
param randomSeed = 'seed-001'
```

## Deployment behavior

The template uses a naming pattern similar to:

```text
{workload}-{environment}-{regioncode}
```

It also adds a randomized suffix to the resource group name to avoid collisions, while preserving a predictable, human-readable base.

## Outputs

After deployment, the template returns values including:

- resource group name
- Foundry account name
- Foundry account endpoint
- project name
- project endpoint
- project principal ID

These are surfaced in the Azure deployment output and can be used in downstream scripts or apps.

## Delete the resource group

The deployment output includes the generated resource group name. To delete the resource group and all resources in it, run:

```powershell
az group delete --name "<resource-group-name>" --yes --no-wait
```

Replace the placeholder with the actual resource group name returned by the deployment. Deletion is destructive and removes every resource in that group. Omit `--no-wait` if you want the command to wait for deletion to finish.

## Notes

- `publicNetworkAccess` can be set to `Disabled`, but this typically requires additional networking and private access configuration.
- `disableLocalAuth = true` is recommended for stricter identity-based access.
- Model deployment requires the selected region and quota to support the chosen model and SKU.

This project is a simple starting point for creating a secure, repeatable Azure AI Foundry environment with minimal configuration overhead.
