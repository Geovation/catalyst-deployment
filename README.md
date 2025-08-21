# Catalyst

Catalyst is a set of tools created to make it easier to deploy infrastructure that uses Ordnance Survey data
We know from working with the Geovation community how frantic early months of development time can be, these tools are designed to take some of the burden away by automically deploying resources in the best way and shorttening the time it takes you to start creating value with Ordnance Survey Data.
There are two Catalyst resources available through this deployment repository.
1) NGD Wrappers - tools to aid the use of the [OS NGD Features API](https://docs.os.uk/osngd/getting-started/access-the-os-ngd-api/os-ngd-api-features).
2) ONS Geographies - a proxy API for appending ONS lookup data to API calls to [OS Places API](https://docs.os.uk/os-apis/accessing-os-apis/os-places-api).
The code which this repository deploys is available at four [Geovation repositories](https://github.com/Geovation), one for each cloud platorm and resource.

# Catalyst Deployment

This repository contains resources to deploy the Catalyst API tools to cloud services, including:

- Azure
- AWS

Using these resources, you can get a **working API up and running in minutes** with minimal manual configuration.

## Azure

Azure deployment has been written using [Azure Resource Manager (ARM)](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/overview) templates.

## AWS

AWS deployment has been written using [CloudFormation templates](https://aws.amazon.com/cloudformation/resources/templates/).

### Instructions

#### 1. **Permissions**

- You will require the following AWS perissions:
    - cloudformation:CreateStack
    - cloudformation:UpdateStack
    - cloudformation:DeleteStack
    - s3:PutObject
    - s3:DeleteObject
    - lambda:InvokeFunction
    - logs:CreateLogGroup
    - logs:CreateLogStream
    - logs:PutLogEvents
- You will also need to create a project on the [OS DataHub](https://osdatahub.os.uk/projects), and ensure that OS NGD API - Features is added to the project.

#### 2. **CloudFormation Stack**

1. Go to the [CloudFormation console](https://eu-west-2.console.aws.amazon.com/cloudformation), select 'Create stack' > 'With new resources (standard)'.
2. Under 'Prerequisite - Prepare template', ensure 'Choose an existing template' is selected, and under 'Specify template' select 'Upload a template file' and upload main.yml from the aws directory.
4. On the 'Specify stack details' step, enter the following parameters:
    - A stack name of your choice
    - If you want automatic internal OS authorisation, set OSDataHubProjectKey and OSDataHubProjectSecret to the corresponding values from your the OS DataHub.
    - If desired, modify the ApiGatewayStageName and other parameters from the defaults.
5. Keep default settings on the 'Configure stack option' page (note the acknowledgement that CloudFormation will create IAM resources), and create the stack.
6. It should take a few minutes for the Stack to build.

#### **_CLI Alternative Method_**

Below is a demonstration of how the AWS CLI could be used as an alternative to the CloudFormation interface.
Find further details and parameters [here](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/create-stack.html).

```
aws configure
    AWS Access Key ID [None]: <your-access-key-id>
    AWS Secret Access Key [None]: <your-secret-access-key>
    Default region name [None]: eu-west-2
    Default output format [None]: json

aws cloudformation create-stack
    --stack-name catalyst-deployment
    --template-body file://path/to/main.yml
    --capabilities CAPABILITY_NAMED_IAM
    --parameters
        ParameterKey=ApiKeyName,ParameterValue=CustomApiKeyName
        ParameterKey=OSDataHubProjectKey,ParameterValue=<your-datahub-key>
        ParameterKey=OSDataHubProjectSecret,ParameterValue=<your-datahub-secret>
```

#### 3. **Accessing the API**

- Links to the various resources, including the Lambda Function and the Gateway API, can be viewed under 'Resources'. If you wish, extra settings (eg. API usage throttling, see below) can be set/changed using these.
- Under 'Outputs', the apiGatewayInvokeURL value provides the root URL which can be used to access the various endpoints.
- For use of the API, please see the documentation under the [catalyst-ngd-wrappers-aws](https://github.com/Geovation/catalyst-ngd-wrappers-aws) repository.

### Authentication

Both API Gateway and OS DataHub authorisation must be configured for use of the API.
- If OSDataHubProjectKey and OSDataHubProjectSecret are left blank in setup, then the Gateway API is left unauthorised, allowing open access to the endpoints.
    - You can add authorisation manually if you wish: for example, by creating a Usage Plan and API key on the [API Gateway console](https://eu-west-2.console.aws.amazon.com/apigateway).
- If you supply OSDataHubProjectKey and OSDataHubProjectSecret in setup, API Gateway key authorisation is automatically enabled, and a key and usage plan generated (see below)
    - You can find the key under "API Keys" on the API Gateway console.
    - This key must be passed to all API requests as the [X-API-Key header](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-api-key-source.html).
    - By default, there is no throttling or quotas to the usage plan. To add these, access the plan through the [API Gateway console](https://eu-west-2.console.aws.amazon.com/apigateway), find your plan under 'Usage plans', select 'Actions'>'Edit usage plan', and configure these settings.

### Stack Deletion

Deleting a stack automatically deletes all associated resources.

However, if you choose to delete a stack, you must **first manually empty the S3 bucket**, as only empty buckets can be deleted automatically. This can be done through the [S3 console](https://eu-west-2.console.aws.amazon.com/s3).

### Resources Overview

Running the main.yaml file automatically generates all the required resources. These resources are summarised below.
Note that an S3 Bucket is used as a temporary code store before is is loaded into lambda functions. This bucket is deleted after use.
The two temporary resources list are not used by the final product, but only required for the initial import of the code.

| Resource                     | Resource Name in `main.yml`         | Resource Type           | Notes                                                                 | Other Associated Resources                                      |
|-----------------------------|-------------------------------------|--------------------------|-----------------------------------------------------------------------|------------------------------------------------------------------|
| Temporary S3 Bucket         | LambdaBucket                        | S3 Bucket                | Storage location for the ONS Geography duckdb database. Also used as an intermediary storage location for the Lambda function code between Github and Lambda functions.    |                                                                  |
| Temporary Bootstrap Function| InitFunction                        | Lambda Function          | Moves the lambda function code and the ONS Geography database from GitHub to S3. Triggered by _Initialize_ and _CleanupBootstrapLambda_ custom resources.   | Initialize, CleanupBootstrapLambda                              |
| NGD Wrappers Function       | NGDWrapperLambdaFunction            | Lambda Function          | Contains code base for NGD Wrappers.                                 | NGDWrapperLambdaRole, NGDWrapperApiGatewayInvoke…               |
| ONS Geographies Function    | ONSGeographiesLambdaFunction        | Lambda Function          | Contains code base for ONS Geographies.                              | ONSGeographiesLambdaRole, ONSGeographiesApiGatewayInvoke        |
| Gateway API                 | ApiGatewayRestApi                   | ApiGateway REST API      | Defines API to trigger Lambda functions.                             |                                                                  |
| NGD Wrappers Endpoints      | EndpointNGD…                        | ApiGateway Resource      | API endpoint definitions for NGD Wrapper.                            |                                                                  |
| ONS Geographies Endpoints   | EndpointONS…                        | ApiGateway Resource      | API endpoint definitions for ONS Geographies.                        |                                                                  |
| NGD Wrappers Methods        | MethodNGD…                          | ApiGateway Method        | API methods to trigger NGD Wrapper endpoints.                        |                                                                  |
| ONS Geographies Method      | MethodONS                           | ApiGateway Method        | API method to trigger ONS Geographies endpoints.                     |                                                                  |
| Gateway API Deployment      | ApiGatewayDeployment                | ApiGateway Deployment    | Packaged publication of the API.                                     |                                                                  |
| Gateway Usage Plan          | UsagePlan                           | ApiGateway Usage Plan    | Usage plan for accessing Gateway API stage. Generated for security **only if OS Datahub credentials are supplied** as parameters for automatic OS authentication.                          |                                                                  |
| Gateway API Key             | ApiKey                              | ApiGateway API Key       | An API key associated with the usage plan and Gateway API stage. Generated for security **only if OS Datahub credentials are supplied** as parameters for automatic OS authentication. |                                                                  |
| Usage Plan <> Key Association| UsagePlanKey                       | ApiGateway Usage Plan Key| Associates API key with usage plan. Generated for security **only if OS Datahub credentials are supplied** as parameters for automatic OS authentication.                                  |                                                                  |

# Feedback and Feature requests

We welcome all feedback, positive and negative. If you have a request for specific features please raise an issue and we will triage and respond as soon as possible

## Licence

All Catalyst resources are hosted under the MIT Licence
