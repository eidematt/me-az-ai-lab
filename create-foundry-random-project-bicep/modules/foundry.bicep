// ============================================================================
// Resource-group-scope module: Foundry resource, project, optional model,
// optional RBAC assignment.
// ============================================================================
targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string

@description('Name of the Foundry resource (AIServices account). Also used as the globally unique custom subdomain.')
@minLength(2)
@maxLength(64)
param foundryAccountName string

@description('Name of the Foundry project (unique within the Foundry resource).')
param foundryProjectName string

@description('Display name of the Foundry project.')
param projectDisplayName string

@description('Description of the Foundry project.')
param projectDescription string

@description('Public network access for the Foundry resource.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string

@description('Disable key-based authentication (Entra ID only).')
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

@description('Optional principal object ID to grant "Azure AI User" on the project.')
param projectUserPrincipalId string

@description('Principal type for projectUserPrincipalId.')
param projectUserPrincipalType string

@description('Tags applied to all resources.')
param tags object

// Built-in role: Azure AI User
var azureAiUserRoleId = '53ca6127-db72-4b80-b1b0-d745d6d5456d'

// ---------------------------------------------------------------------------
// Foundry resource (new Foundry model: AIServices + project management)
// ---------------------------------------------------------------------------
resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: foundryAccountName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    allowProjectManagement: true
    customSubDomainName: foundryAccountName // immutable after creation
    publicNetworkAccess: publicNetworkAccess
    disableLocalAuth: disableLocalAuth
    networkAcls: {
      defaultAction: publicNetworkAccess == 'Enabled' ? 'Allow' : 'Deny'
    }
  }
}

// ---------------------------------------------------------------------------
// Foundry project
// ---------------------------------------------------------------------------
resource foundryProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: foundryAccount
  name: foundryProjectName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: projectDisplayName
    description: projectDescription
  }
}

// ---------------------------------------------------------------------------
// Optional model deployment (account level, available to all projects)
// ---------------------------------------------------------------------------
resource modelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = if (deployModel) {
  parent: foundryAccount
  name: modelName
  sku: {
    name: modelSkuName
    capacity: modelCapacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: modelName
      version: modelVersion
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
  }
  dependsOn: [
    foundryProject
  ]
}

// ---------------------------------------------------------------------------
// Optional RBAC: Azure AI User on the project
// ---------------------------------------------------------------------------
resource projectUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(projectUserPrincipalId)) {
  name: guid(foundryProject.id, projectUserPrincipalId, azureAiUserRoleId)
  scope: foundryProject
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', azureAiUserRoleId)
    principalId: projectUserPrincipalId
    principalType: projectUserPrincipalType
  }
}

// ---------------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------------
output foundryAccountName string = foundryAccount.name
output foundryAccountId string = foundryAccount.id
output foundryAccountEndpoint string = foundryAccount.properties.endpoint
output foundryProjectName string = foundryProject.name
output foundryProjectId string = foundryProject.id
output foundryProjectEndpoint string = 'https://${foundryAccountName}.services.ai.azure.com/api/projects/${foundryProjectName}'
output foundryProjectPrincipalId string = foundryProject.identity.principalId
