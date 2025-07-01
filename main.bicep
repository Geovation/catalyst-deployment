@description('Name of the workspace - this name will be used in resources')
param workspaceName string = 'catalyst'

@description('Location for all resources.')
param location string = 'UK West'
@description('Name of the ONS Proxy API resources')
param onsProxyApiName string = 'ons-proxy-api'

@description('Name of the NGD Wrapper Function resources')
param ngdWrapperName string = 'ngd-wrapper-functions'

var logAnalyticsName = toLower('${workspaceName}-log-analytics')

var onsProxyApiServicePlanName = '${onsProxyApiName}-serviceplan'
var onsProxyApiFunctionName = '${onsProxyApiName}-function'
var onsProxyApiStoreName = replace(toLower('${onsProxyApiName}store'), '-', '')
var onsProxyApiInsightsName = '${onsProxyApiName}-insights'
var onsProxyFunctionsPackageUri = 'https://raw.githubusercontent.com/Geovation/catalyst-azure/refs/heads/main/catalyst-ons-proxy-api-azure-0.1.0.zip'

var ngdWrapperServicePlanName = '${ngdWrapperName}-serviceplan'
var ngdWrapperFunctionName = '${ngdWrapperName}-function'
var ngdWrapperStoreName = replace(toLower('${ngdWrapperName}store'), '-', '')
var ngdWrapperInsightsName = '${ngdWrapperName}-insights'
var ngdWrapperFunctionsPackageUri = 'https://raw.githubusercontent.com/Geovation/catalyst-azure/refs/heads/main/catalyst-ngd-wrapper-functions-python-app.zip'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
  }
}

resource ngdWrapperStorage 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: ngdWrapperStoreName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource onsProxyStorage 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: onsProxyApiStoreName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource onsProxyServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: onsProxyApiServicePlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  kind: 'functionapp'
  properties: {
    reserved: true
  }
}

resource ngdWrapperServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: ngdWrapperServicePlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  kind: 'functionapp'
  properties: {
    reserved: true
  }
}

resource ngdWrapperAppInsights 'microsoft.insights/components@2020-02-02' = {
  name: ngdWrapperInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaAIExtensionEnablementBlade'
    RetentionInDays: 90
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource onsProxyAppInsights 'microsoft.insights/components@2020-02-02' = {
  name: onsProxyApiInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'IbizaAIExtensionEnablementBlade'
    RetentionInDays: 90
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource ngdWrapperFunctionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: ngdWrapperFunctionName
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: ngdWrapperServicePlan.id
    reserved: true
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'PYTHON|3.11'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(resourceId('Microsoft.Insights/components', ngdWrapperInsightsName), '2015-05-01').InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${ngdWrapperStoreName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${ngdWrapperStorage.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${ngdWrapperStoreName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${ngdWrapperStorage.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(ngdWrapperFunctionName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
      ]
    }
  }
}

resource onsProxyFunctionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: onsProxyApiFunctionName
  location: location
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: onsProxyServicePlan.id
    reserved: true
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'PYTHON|3.11'
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: reference(resourceId('Microsoft.Insights/components', onsProxyApiInsightsName), '2015-05-01').InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${onsProxyApiStoreName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${onsProxyStorage.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${onsProxyApiStoreName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${onsProxyStorage.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(onsProxyApiFunctionName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
      ]
    }
  }
}

resource ngdWrapperZipDeploy 'Microsoft.Web/sites/extensions@2022-03-01' = {
  parent: ngdWrapperFunctionApp
  name: any('zipdeploy')
  location: location
  properties: {
    packageUri: ngdWrapperFunctionsPackageUri
  }
}

resource onsProxyZipDeploy 'Microsoft.Web/sites/extensions@2022-03-01' = {
  parent: onsProxyFunctionApp
  name: any('zipdeploy')
  location: location
  properties: {
    packageUri: onsProxyFunctionsPackageUri
  }
}
