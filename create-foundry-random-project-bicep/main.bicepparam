// Environment-specific values. Copy per environment (e.g. dev.bicepparam, prod.bicepparam).
using './main.bicep'

param workload = 'aiapp'
param environment = 'dev'
param location = 'eastus2'
// param regionCode = 'eus2'   // optional override of the built-in region map

// Uncomment and pin to re-deploy into the SAME randomized resource group.
// param randomSeed = 'seed-001'

param publicNetworkAccess = 'Enabled'
param disableLocalAuth = true

param deployModel = true
param modelName = 'gpt-4.1-mini'
param modelVersion = '2025-04-14'
param modelSkuName = 'GlobalStandard'
param modelCapacity = 10

// Optional: Entra group/user object ID to grant "Azure AI User" on the project
param projectUserPrincipalId = ''
param projectUserPrincipalType = 'Group'

param tags = {
  owner: 'platform-team'
  costCenter: 'it'
}
