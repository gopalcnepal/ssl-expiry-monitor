
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
