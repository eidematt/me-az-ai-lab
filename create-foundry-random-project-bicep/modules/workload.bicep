// ============================================================================
// Subscription-scope module: creates the resource group and deploys Foundry
// ============================================================================
targetScope = 'subscription'

@description('Azure region for the resource group and all resources.')
param location string

@description('Name of the resource group to create.')
param resourceGroupName string

@description('Name of the Foundry resource (also used as the global custom subdomain).')
param foundryAccountName string

@description('Name of the Foundry project.')
param foundryProjectName string

@description('Display name of the Foundry project.')
param projectDisplayName string

@description('Description of the Foundry project.')
param projectDescription string

@description('Public network access for the Foundry resource.')
param publicNetworkAccess string

@description('Disable key-based authentication.')
param disableLocalAuth bool

@description('Deploy a model to the Foundry resource.')
param deployModel bool

@description('Model name.')
param modelName string

@description('Model version.')
param modelVersion string

@description('Model deployment SKU.')
param modelSkuName string

@description('Model capacity (thousands of TPM).')
param modelCapacity int

@description('Optional principal to grant Azure AI User on the project.')
param projectUserPrincipalId string

@description('Principal type for projectUserPrincipalId.')
param projectUserPrincipalType string

@description('Tags applied to all resources.')
param tags object

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module foundry 'foundry.bicep' = {
  name: 'foundry-resources'
  scope: rg
  params: {
    location: location
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
    tags: tags
  }
}

output resourceGroupName string = rg.name
output foundryAccountName string = foundry.outputs.foundryAccountName
output foundryAccountId string = foundry.outputs.foundryAccountId
output foundryAccountEndpoint string = foundry.outputs.foundryAccountEndpoint
output foundryProjectName string = foundry.outputs.foundryProjectName
output foundryProjectId string = foundry.outputs.foundryProjectId
output foundryProjectEndpoint string = foundry.outputs.foundryProjectEndpoint
output foundryProjectPrincipalId string = foundry.outputs.foundryProjectPrincipalId
