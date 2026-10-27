// ============================================================================
// Microsoft Foundry project – entry point (subscription scope)
// Creates a new resource group with a randomized suffix, then deploys a
// Foundry resource (AIServices account) and a Foundry project into it.
// Naming convention: {resource}-{workload}-{environment}-{region}
// ============================================================================
targetScope = 'subscription'

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------
@description('Target subscription ID for all resources. Defaults to the subscription the deployment is run against. Set this to deploy into a different subscription you have Contributor/Owner rights on.')
param subscriptionId string = subscription().subscriptionId

@description('Short workload name used in every resource name (lowercase letters/numbers, 2-12 chars). Example: "aiapp".')
@minLength(2)
@maxLength(12)
param workload string

@description('Deployment environment. Used in resource names and tags.')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string

@description('Azure region for all resources (e.g. "eastus2"). Must be a region where Foundry projects and any requested model are available.')
param location string

@description('Optional region short code used in resource names (e.g. "eus2"). Leave empty to derive it from the built-in region map; unmapped regions fall back to the full region name.')
param regionCode string = ''

@description('Seed for the resource group randomization. Defaults to the current UTC time, so every run creates a NEW resource group. Pin this to a fixed value to make re-runs idempotent (update the same resource group).')
param randomSeed string = utcNow()

@description('Display name shown for the project in the Foundry portal.')
param projectDisplayName string = '${workload} ${environment} project'

@description('Description of the Foundry project.')
param projectDescription string = 'Foundry project for the ${workload} workload (${environment}).'

@description('Public network access for the Foundry resource. Use "Disabled" only if private endpoints will be added separately.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Disable key-based (local) authentication and require Microsoft Entra ID. Recommended: true.')
param disableLocalAuth bool = true

@description('Deploy a model to the Foundry resource. When false, the model parameters below are ignored.')
param deployModel bool = false

@description('Model name to deploy (e.g. "gpt-4.1-mini"). Must be available in the selected region and SKU.')
param modelName string = 'gpt-4.1-mini'

@description('Model version to deploy (e.g. "2025-04-14"). Must match a published version for the model.')
param modelVersion string = '2025-04-14'

@description('Model deployment SKU (e.g. "GlobalStandard", "Standard", "DataZoneStandard").')
param modelSkuName string = 'GlobalStandard'

@description('Model deployment capacity in thousands of tokens per minute (TPM). Subject to subscription quota.')
@minValue(1)
param modelCapacity int = 10

@description('Optional Entra object ID of a user, group, or service principal to grant the "Azure AI User" role on the project. Leave empty to skip.')
param projectUserPrincipalId string = ''

@description('Principal type for projectUserPrincipalId.')
@allowed([
  'User'
  'Group'
  'ServicePrincipal'
])
param projectUserPrincipalType string = 'Group'

@description('Additional tags merged onto every resource.')
param tags object = {}

// ---------------------------------------------------------------------------
// Variables
// ---------------------------------------------------------------------------
var regionCodes = {
  eastus: 'eus'
  eastus2: 'eus2'
  centralus: 'cus'
  northcentralus: 'ncus'
  southcentralus: 'scus'
  westus: 'wus'
  westus2: 'wus2'
  westus3: 'wus3'
  westcentralus: 'wcus'
  canadacentral: 'cac'
  canadaeast: 'cae'
  uksouth: 'uks'
  ukwest: 'ukw'
  westeurope: 'weu'
  northeurope: 'neu'
  swedencentral: 'sdc'
  francecentral: 'frc'
  germanywestcentral: 'gwc'
  switzerlandnorth: 'chn'
  norwayeast: 'noe'
  australiaeast: 'aue'
  japaneast: 'jpe'
  koreacentral: 'krc'
  southindia: 'ins'
}

var resolvedRegionCode = toLower(!empty(regionCode) ? regionCode : (regionCodes[?location] ?? location))
var baseName = toLower('${workload}-${environment}-${resolvedRegionCode}')

// Randomized suffix for the resource group (explicitly requested)
var rgSuffix = take(uniqueString(subscriptionId, baseName, randomSeed), 5)

// Foundry resource name doubles as the global custom subdomain -> must be globally unique
var accountSuffix = take(uniqueString(subscriptionId, baseName, rgSuffix), 5)

var resourceGroupName = 'rg-${baseName}-${rgSuffix}'
var foundryAccountName = 'aif-${baseName}-${accountSuffix}'
var foundryProjectName = 'proj-${baseName}' // scoped to the account -> no randomization needed

var commonTags = union({
  workload: workload
  environment: environment
  region: location
  managedBy: 'bicep'
}, tags)

// ---------------------------------------------------------------------------
// Deployment (scoped to the chosen subscription)
// ---------------------------------------------------------------------------
module workloadDeployment 'modules/workload.bicep' = {
  name: 'foundry-${baseName}-${rgSuffix}'
  scope: subscription(subscriptionId)
  params: {
    location: location
    resourceGroupName: resourceGroupName
    foundryAccountName: foundryAccountName
    foundryProjectName: foundryProjectName
    projectDisplayName: projectDisplayName
    projectDescription: projectDescription
    publicNetworkAccess: publicNetworkAccess
    disableLocalAuth: disableLocalAuth
    deployModel: deployModel
    modelName: modelName
    modelVersion: modelVersion
    modelSkuName: modelSkuName
    modelCapacity: modelCapacity
    projectUserPrincipalId: projectUserPrincipalId
    projectUserPrincipalType: projectUserPrincipalType
    tags: commonTags
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
@description('Name of the newly created resource group.')
output resourceGroupName string = workloadDeployment.outputs.resourceGroupName

@description('Name of the Foundry resource (AIServices account).')
output foundryAccountName string = workloadDeployment.outputs.foundryAccountName

@description('Resource ID of the Foundry resource.')
output foundryAccountId string = workloadDeployment.outputs.foundryAccountId

@description('Endpoint of the Foundry resource.')
output foundryAccountEndpoint string = workloadDeployment.outputs.foundryAccountEndpoint

@description('Name of the Foundry project.')
output foundryProjectName string = workloadDeployment.outputs.foundryProjectName

@description('Resource ID of the Foundry project.')
output foundryProjectId string = workloadDeployment.outputs.foundryProjectId

@description('Foundry project endpoint for the Azure AI Projects SDK / Agent Service.')
output foundryProjectEndpoint string = workloadDeployment.outputs.foundryProjectEndpoint

@description('Object ID of the project system-assigned managed identity.')
output foundryProjectPrincipalId string = workloadDeployment.outputs.foundryProjectPrincipalId
