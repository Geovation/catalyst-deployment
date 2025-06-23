param sites_catalyst_ons_proxy_api_name string = 'catalyst-ons-proxy-api'
param sites_catalyst_ngd_wrapper_functions_name string = 'catalyst-ngd-wrapper-functions'
param components_catalyst_ons_proxy_api_name string = 'catalyst-ons-proxy-api'
param components_catalyst_ngd_wrapper_functions_name string = 'catalyst-ngd-wrapper-functions'
param storageAccounts_catalystngdwrappersstore_name string = 'catalystngdwrappersstore'
param storageAccounts_catalystonsproxyapistore_name string = 'catalystonsproxyapistore'
param workspaces_catalyst_log_analytics_name string = 'catalyst-log-analytics'
param serverfarms_ASP_catalyst_ons_proxy_api_serviceplan_name string = 'catalyst_ons_proxy_api_serviceplan'
param serverfarms_ASP_catalyst_ngd_wrapper_serviceplan_name string = 'catalyst_ngd_wrapper_serviceplan'
param ngdWrappersFunctionsPackageUri string = 'https://raw.githubusercontent.com/Geovation/catalyst-azure/refs/heads/main/catalyst-ngd-wrapper-functions-python-app.zip'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: workspaces_catalyst_log_analytics_name
  location: 'ukwest'
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 30
    features: {
      legacy: 0
      searchVersion: 1
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: json('-1')
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource ngdWrapperStorage 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccounts_catalystngdwrappersstore_name
  location: 'ukwest'
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource onsProxyStorage 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccounts_catalystonsproxyapistore_name
  location: 'ukwest'
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource onsProxyServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: serverfarms_ASP_catalyst_ons_proxy_api_serviceplan_name
  location: 'UK West'
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    size: 'Y1'
    family: 'Y'
    capacity: 0
  }
  kind: 'functionapp'
  properties: {
    perSiteScaling: false
    elasticScaleEnabled: false
    maximumElasticWorkerCount: 1
    isSpot: false
    reserved: true
    isXenon: false
    hyperV: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
    zoneRedundant: false
  }
}

resource ngdWrapperServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: serverfarms_ASP_catalyst_ngd_wrapper_serviceplan_name
  location: 'UK West'
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
  name: components_catalyst_ngd_wrapper_functions_name
  location: 'ukwest'
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
  name: components_catalyst_ons_proxy_api_name
  location: 'ukwest'
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
  name: sites_catalyst_ngd_wrapper_functions_name
  location: 'UK West'
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
          value: reference(resourceId('Microsoft.Insights/components', sites_catalyst_ngd_wrapper_functions_name), '2015-05-01').InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccounts_catalystngdwrappersstore_name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${ngdWrapperStorage.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccounts_catalystngdwrappersstore_name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${ngdWrapperStorage.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(sites_catalyst_ngd_wrapper_functions_name)
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
  name: sites_catalyst_ons_proxy_api_name
  location: 'UK West'
  kind: 'functionapp,linux'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${sites_catalyst_ons_proxy_api_name}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${sites_catalyst_ons_proxy_api_name}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Repository'
      }
    ]
    serverFarmId: onsProxyServicePlan.id
    reserved: true
    isXenon: false
    hyperV: false
    dnsConfiguration: {}
    vnetRouteAllEnabled: false
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    siteConfig: {
      numberOfWorkers: 1
      linuxFxVersion: 'PYTHON|3.11'
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      functionAppScaleLimit: 200
      minimumElasticInstanceCount: 1
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: false
    clientCertEnabled: false
    clientCertMode: 'Required'
    hostNamesDisabled: false
    ipMode: 'IPv4'
    vnetBackupRestoreEnabled: false
    customDomainVerificationId: 'E419F9B1DCCA4BC29CDFB13EA6FF14EB219BE5A719EAD6C23BEC86CE6917D221'
    containerSize: 1536
    dailyMemoryTimeQuota: 0
    httpsOnly: true
    endToEndEncryptionEnabled: false
    redundancyMode: 'None'
    publicNetworkAccess: 'Enabled'
    storageAccountRequired: false
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
}

resource ngdWrapperZipDeploy 'Microsoft.Web/sites/extensions@2022-03-01' = {
  parent: ngdWrapperFunctionApp
  name: any('zipdeploy')
  location: 'UK West'
  properties: {
    packageUri: ngdWrappersFunctionsPackageUri
  }
}
