@description('Location for all resources.')
param location string = resourceGroup().location

@secure()
param webhookSecret string

var storageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'

resource storage 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: 'acarunner'
}

resource acr 'Microsoft.ContainerRegistry/registries@2022-02-01-preview' existing = {
  name: 'acarunners'
}

resource acarunnerenv 'Microsoft.App/managedEnvironments@2022-06-01-preview' existing = {
  name: 'aca-runner'
}

resource acascaler 'Microsoft.App/containerApps@2022-06-01-preview' = {
  // (2-32) Lowercase letters, numbers, and hyphens
  name: 'acascalers'
  location: location
  properties: {
    environmentId: acarunnerenv.id
    configuration: {
      activeRevisionsMode: 'single'
      registries: [
        {
          server: acr.properties.loginServer
          username: acr.listCredentials().username
          passwordSecretRef: 'acr-password'
        }
      ]
      secrets: [
        { name: 'acr-password', value: acr.listCredentials().passwords[0].value }
        { name: 'storage-connection-string', value: storageConnectionString }
        { name: 'webhook-secret', value: webhookSecret }
      ]
      dapr: { enabled: false }
      ingress: {
        external: true
        targetPort: 80
        ipSecurityRestrictions: [
          { name: 'GitHub Hooks 1', action: 'Allow', ipAddressRange: '192.30.252.0/22' }
          { name: 'GitHub Hooks 2', action: 'Allow', ipAddressRange: '185.199.108.0/22' }
          { name: 'GitHub Hooks 3', action: 'Allow', ipAddressRange: '140.82.112.0/20' }
          { name: 'GitHub Hooks 4', action: 'Allow', ipAddressRange: '143.55.64.0/20' }
        ]
      }
    }
    template: {
      containers: [
        {
          name: 'acascaler'
          image: '${acr.properties.loginServer}/acascaler:latest'
          resources: { cpu: 2, memory: '4Gi' }
          env: [
            { name: 'STORAGE_CONNECTION_STRING', secretRef: 'storage-connection-string' }
            { name: 'STORAGE_QUEUE_NAME', value: 'aca-runner-scaler' }
            { name: 'WEBHOOK_SECRET', secretRef: 'webhook-secret' }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
        rules: [
          {
            name: 'httpscalingrule'
            http: {
              metadata: {
                concurrentRequests: '20'
              }
            }
          }
        ]
      }
    }
  }
}

output url string = acascaler.properties.configuration.ingress.fqdn
