@description('Location for all resources.')
param location string = resourceGroup().location

@secure()
param pat string

param org string = 'colbylwilliams'
param repo string = 'aca-runner-test'

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

resource acarunner 'Microsoft.App/containerApps@2022-06-01-preview' = {
  // (2-32) Lowercase letters, numbers, and hyphens
  name: 'acarunners'
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
        { name: 'gh-token', value: pat }
        { name: 'acr-password', value: acr.listCredentials().passwords[0].value }
        { name: 'storage-connection-string', value: storageConnectionString }
      ]
      dapr: { enabled: false }
    }
    template: {
      containers: [
        {
          name: 'acarunner'
          image: '${acr.properties.loginServer}/acarunner:latest'
          resources: { cpu: 2, memory: '4Gi' }
          env: [
            { name: 'GH_OWNER', value: org }
            { name: 'GH_REPOSITORY', value: repo }
            { name: 'GH_TOKEN', secretRef: 'gh-token' }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 5
        rules: [
          {
            name: 'queue-scaling'
            azureQueue: {
              queueName: 'aca-runner-scaler'
              queueLength: 1
              auth: [
                {
                  secretRef: 'storage-connection-string'
                  triggerParameter: 'connection'
                }
              ]
            }
          }
        ]
      }
    }
  }
  tags: {}
}
