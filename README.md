# Catalyst

Catalyst is a set of tools created to make it easier to deploy infrastructure that uses Ordnance Survey data 

# Catalyst deployment

This repository contains resources to deploy the Catalyst API tools to cloud services, including:

- Azure
- AWS

## Azure

Azure deployment has been written using [Azure Resource Manager (ARM)](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/overview) templates.

## AWS

AWS deployment has been written using [CloudFormation templates](https://aws.amazon.com/cloudformation/resources/templates/).

### Resource Overview

| Resource                     | Resource Name in `main.yml`         | Resource Type       | Notes                                                                 | Other Associated Resources                                           |
|-----------------------------|-------------------------------------|---------------------|-----------------------------------------------------------------------|----------------------------------------------------------------------|
| Temporary S3 Bucket         | `LambdaBucket`                      | S3 Bucket           | Intermediary storage location for code between GitHub and Lambda. **DELETED** by CloudFormation after use.     |                                                                      |
| Temporary Bootstrap Function| `InitFunction`                      | Lambda Function     | Moves code from GitHub to S3. Triggered by `Initialize` and `CleanupBootstrapLambda`. | `Initialize`, `CleanupBootstrapLambda`                              |
| NGD Wrappers Function       | `NGDWrapperLambdaFunction`          | Lambda Function     | Contains code base for NGD Wrappers.                                  | `NGDWrapperLambdaRole`, all `NGDWrapperApiGatewayInvoke…` resources |
| ONS Geographies Function    | `ONSGeographiesLambdaFunction`      | Lambda Function     | Contains code base for ONS Geographies.                               | `ONSGeographiesLambdaRole`, `ONSGeographiesApiGatewayInvoke`        |
| Gateway API                 | `ApiGatewayRestApi`                 | ApiGateway REST API | Defines API to trigger Lambda functions.                              |                                                                      |
| NGD Wrappers Endpoints      | `EndpointNGD…`                      | ApiGateway Resource | API endpoint definitions for NGD Wrapper.                             |                                                                      |
| ONS Geographies Endpoints   | `EndpointONS…`                      | ApiGateway Resource | API endpoint definitions for ONS Geographies.                         |                                                                      |
| NGD Wrappers Methods        | `MethodNGD…`                        | ApiGateway Method   | API methods to trigger NGD Wrapper endpoints.                         |                                                                      |
| ONS Geographies Method      | `MethodONS`                         | ApiGateway Method   | API method to trigger ONS Geographies endpoints.                      |                                                                      |
| Gateway API Deployment      | `ApiGatewayDeployment`              | ApiGateway Deployment| Packaged publication of the API.                                      |                                                                      |

## Licence

MIT Licence
