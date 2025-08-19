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

1) Permissions
- You will require the following AWS perissions:
    - cloudformation:CreateStack
    - cloudformation:UpdateStack
    - cloudformation:DeleteStack
    - s3:PutObject
    - s3:DeleteObject
    - s3:DeleteBucket
    - lambda:InvokeFunction
    - logs:CreateLogGroup
    - logs:CreateLogStream
    - logs:PutLogEvents
- You will also need to create a project on the [OS DataHub](https://osdatahub.os.uk/projects), and ensure that OS NGD API - Features is added to the project.
2) CloudFormation Stack
- Go to the [CloudFormation console](https://eu-west-2.console.aws.amazon.com/cloudformation), select 'Create stack' > 'With new resources (standard)'.
- Under 'Prerequisite - Prepare template' ensure 'Choose an existing template' is selected.
- Under 'Specify template' select 'Upload a template file' and upload main.yml from the aws directory.
- On the 'Specify stack details' step, enter the following parameters:
    - A stack name of your choice
    - Set OSDataHubProjectKey and OSDataHubProjectSecret to the corresponding values from your the OS DataHub.
    - If desired, modify the ApiGatewayStageName and other parameters from the defaults.
- Keep default settings on the 'Configure stack option' page (note the acknowledgement that CloudFormation will create IAM resources), and create the stack.
- It should take a few minutes for the Stack to build.
3) Accessing the API
- The various resources, including the Lambda Function and the Gateway API, can be viewed under 'Resources'.
- Under 'Outputs', the apiGatewayInvokeURL value provides the base URL which can be used to access the various endpoints.
- For use the API, please see the documentation under the [catalyst-ngd-wrappers-aws](https://github.com/Geovation/catalyst-ngd-wrappers-aws) repository.

### Resources Overview

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
