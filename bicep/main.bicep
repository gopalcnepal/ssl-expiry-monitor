
param serverEnv string = 'production'
@secure()
param pgAdminPassword string = newGuid() // Generate a random password
param location string = resourceGroup().location

var uniqueStringValue = uniqueString(resourceGroup().id)

var acrName = 'acr${uniqueStringValue}'
var kvName = 'kv${uniqueStringValue}'
var pgServerName = 'pg${uniqueStringValue}'
var databaseName = 'ssldatabase'
var webAppName = 'webapp${uniqueStringValue}'
var managedIdentityName = 'id${uniqueStringValue}'
var pgAdminUser = 'pgadmin'


// User-Assigned Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
}


// Azure Container Registry (ACR)
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}


// Azure Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  properties: {
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    publicNetworkAccess: 'Enabled'
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
  }
}


// PostgreSQL Flexible Server
resource pgServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: pgServerName
  location: location
  properties: {
    administratorLogin: pgAdminUser
    administratorLoginPassword: pgAdminPassword
    version: '16'
    storage: {
      storageSizeGB: 32
    }
    network: {
      publicNetworkAccess: 'Enabled'
    }
  }
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
}


// Create database
resource postgresqlDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  name: databaseName
  parent: pgServer
  properties: {
    charset: 'UTF8'
    collation: 'en_US.UTF8'
  }
}


// Store PostgreSQL credentials in Key Vault
resource kvSecretPgUser 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'pgAdminUser'
  properties: {
    value: pgAdminUser
  }
}


resource kvSecretPgPassword 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'pgAdminPassword'
  properties: {
    value: pgAdminPassword
  }
}


resource kvSecretDbName 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'postgresqlDatabaseName'
  parent: keyVault
  properties: {
    value: databaseName
  }
}


resource kvSecretPgUrl 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'postgresqlUrl'
  parent: keyVault
  properties: {
    value: '${pgServer.name}.postgres.database.azure.com'
  }
}


// Create app service plan
resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'appServicePlan${uniqueStringValue}'
  location: location
  kind: 'linux'
  sku: {
    name: 'F1'
    tier: 'Free'
  }
  properties: {
    reserved: true
  }
}


// Web App with Managed Identity
resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: webAppName
  location: location
  kind: 'app,linux,container'
  dependsOn: [
    acr
    acrRoleAssignment
  ]
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    siteConfig: {
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: managedIdentity.properties.clientId
      appSettings: [
        {
          name: 'SERVER_ENV'
          value: serverEnv
        }
        {
          name: 'POSTGRESQL_ADMIN_USER'
          value: '@Microsoft.KeyVault(SecretUri=${kvSecretPgUser.properties.secretUri})'
        }
        {
          name: 'POSTGRESQL_ADMIN_PASSWORD'
          value: '@Microsoft.KeyVault(SecretUri=${kvSecretPgPassword.properties.secretUri})'
        }
        {
          name: 'POSTGRESQL_URL'
          value: '@Microsoft.KeyVault(SecretUri=${kvSecretPgUrl.properties.secretUri})'
        }
        {
          name: 'POSTGRESQL_DATABASE_NAME'
          value: '@Microsoft.KeyVault(SecretUri=${kvSecretDbName.properties.secretUri})'
        }
      ]
    }
    serverFarmId: appServicePlan.id
  }
}


resource postgresqlFirewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-08-01' = {
  parent: pgServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}


// Assign Managed Identity Role for ACR Pull
resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, '7f951dda-4ed3-4680-a7ca-43fe172d538d', managedIdentity.id)
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // ACR Pull
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}


resource keyVaultSystemIdentityRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, 'system-identity-keyvault-secret-reader')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6') // Key Vault Secrets User
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}


// Azure Function App Deployment

// Storage Account as required by Azure Functions
resource storageaccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'storage${uniqueStringValue}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

// Create blob container in storage account
resource blobservice 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  name: 'default'
  parent: storageaccount
}

resource functionContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  name: 'container${uniqueStringValue}'
  parent: blobservice
  properties: {
    publicAccess: 'None'
  }
}


// Application Insights for Azure Functions
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'appInsights${uniqueStringValue}'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

// App Service Plan for Azure Functions
resource functionAppPlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'functionAppPlan${uniqueStringValue}'
  location: location
  kind: 'functionapp'
  sku: {
    tier: 'FlexConsumption'
    name: 'FC1'
  }
  properties: {
    reserved: true
  }
}

// Azure Functions
resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: 'functionApp${uniqueStringValue}'
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: functionAppPlan.id
    siteConfig: {
      appSettings: [
        { 
          name: 'SSL_MONITOR_URL'
          value: 'https://${webApp.properties.defaultHostName}/update' // Domain Update URL from web app
        }
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageaccount.name
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsights.properties.ConnectionString
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
      ]
    }
    functionAppConfig:{
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storageaccount.properties.primaryEndpoints.blob}${functionContainer.name}'
          authentication: {
            type: 'SystemAssignedIdentity'
          }
        }
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 100
        instanceMemoryMB: 2048
      }
      runtime: { 
        name: 'python'
        version: '3.12'
      }
    }
  }
}

var storageRoleDefinitionId  = 'b7e6dc6d-f1e8-4753-8033-0f276bb0955b' //Storage Blob Data Owner role

// Allow access from function app to storage account using a managed identity
resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageaccount.id, storageRoleDefinitionId)
  scope: storageaccount
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageRoleDefinitionId)
    principalId: functionApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
