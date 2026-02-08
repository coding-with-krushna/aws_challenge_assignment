# AWS VPC API Gateway Challenge

This assignment demonstrates a serverless architecture using AWS services to build a secure, scalable VPC management API.

## 1. Overview

This assignment is solved using the following **AWS Serverless Services**:

- **API Gateway**: REST API with Cognito authentication for secure access
- **AWS Lambda**: Serverless compute for business logic execution
- **AWS DynamoDB**: NoSQL database for VPC data storage
- **AWS Cognito**: User authentication and authorization
- **VPC**: Network isolation and security
- **Terraform**: Infrastructure as Code (IaC) for resource provisioning

### Architecture Diagram

```
┌──────────────┐      ┌───────────────┐      ┌──────────────┐
│   Cognito    │─────▶│  API Gateway  │─────▶│    Lambda    │
│  User Pool   │      │  (Authorized) │      │   Function   │
└──────────────┘      └───────────────┘      └──────┬───────┘
                                                     │
                                                     ▼
                                              ┌──────────────┐
                                              │   DynamoDB   │
                                              │     Table    │
                                              └──────────────┘
```

## 2. Prerequisites

- AWS Account with appropriate permissions
- AWS CLI installed and configured
- Terraform >= 1.0
- Python 3.9 or later
- Postman (for API testing)

## 3. Setup Instructions

### Step 1: Configure AWS CLI

Configure AWS CLI with your access key and secret access key:

```bash
aws configure
```

You will be prompted to enter:
- **AWS Access Key ID**: Your AWS access key
- **AWS Secret Access Key**: Your AWS secret access key
- **Default region name**: `us-east-1` (or your preferred region)
- **Default output format**: `json`

Verify the configuration:
```bash
aws sts get-caller-identity
```

### Step 2: Create Terraform State Bucket

Create an S3 bucket to store Terraform state. The bucket name should be **unique** across all AWS accounts.

```bash
aws s3api create-bucket --bucket 415699578050-us-east-1-state-bucket --region us-east-1
```

**Important Notes**:
- Replace `415699578050` with your AWS Account ID
- Bucket names must be globally unique
- The bucket name format: `<account-id>-<region>-state-bucket`

Enable versioning on the state bucket (recommended):
```bash
aws s3api put-bucket-versioning --bucket 415699578050-us-east-1-state-bucket --versioning-configuration Status=Enabled
```

### Step 3: Initialize Terraform

Navigate to the terraform directory and initialize:

```bash
cd terraform
terraform init
```

This will:
- Download required provider plugins
- Initialize the backend
- Prepare the working directory

### Step 4: Plan and Apply Terraform Configuration

Review the infrastructure changes:
```bash
terraform plan
```

Apply the configuration to create resources:
```bash
terraform apply
```

Type `yes` when prompted to confirm.

### Step 5: Capture Terraform Outputs

After successful deployment, Terraform will display important outputs:

```
Outputs:

api_url = "https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/prod"
cognito_client_id = "xxxxxxxxxxxxxxxxxxxxxxxxxx"
cognito_user_pool_id = "us-east-1_xxxxxxxxx"
```

**Save these values** - you'll need them for testing!

## 4. Create Test User in Cognito

### Step 1: Create Admin User

Create a test user in the Cognito User Pool:

```bash
aws cognito-idp admin-create-user \
  --user-pool-id <user-pool-id> \
  --username demo-user \
  --user-attributes Name=email,Value=demo@example.com \
  --message-action SUPPRESS
```

Replace `<user-pool-id>` with the value from Terraform output.

### Step 2: Set Permanent Password

Set a permanent password for the user:

```bash
aws cognito-idp admin-set-user-password \
  --user-pool-id <user-pool-id> \
  --username demo-user \
  --password "DemoPass123!" \
  --permanent
```

### Step 3: Generate Authentication Token

Authenticate and get an ID token:

```bash
aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --client-id <client-id> \
  --auth-parameters USERNAME=demo-user,PASSWORD="DemoPass123!"
```

Replace `<client-id>` with the `cognito_client_id` from Terraform output.

**Sample Response**:
```json
{
    "AuthenticationResult": {
        "AccessToken": "eyJraWQiOiJ...",
        "ExpiresIn": 3600,
        "TokenType": "Bearer",
        "RefreshToken": "eyJjdHkiOiJ...",
        "IdToken": "eyJraWQiOiJxV..."
    }
}
```

**Copy the `IdToken` value** - you'll use this in Postman.

## 5. Testing with Postman

### Step 1: Import Postman Collection

1. Open Postman
2. Click **Import** (top-left)
3. Select **File** tab
4. Navigate to `d:\my-work\projects\aws_challenge_assignment\VPC Management API.postman_collection.json`
5. Click **Open**

### Step 2: Configure Collection Variables

1. Click on the imported collection
2. Go to **Variables** tab
3. Update the following variables:

| Variable | Value | Description |
|----------|-------|-------------|
| `baseUrl` | From Terraform output | API Gateway endpoint |
| `id_token` | From authentication | ID Token from Cognito |

4. Click **Save**

### Step 3: Add Authorization Header

For each API request: use the **Authorization** tab:
1. Select **Type**: `Bearer Token`
2. **Token**: `{{id_token}}`

### Step 4: Available API Endpoints

The collection includes the following requests:

#### 1. **GET /v1/vpc** - List all VPCs
- **Method**: GET
- **URL**: `{{baseUrl}}/v1/vpc`
- **Auth**: Required
- **Response**: List of VPC configurations

#### 2. **POST /v1/vpc** - Create a new VPC
- **Method**: POST
- **URL**: `{{baseUrl}}/v1/vpc`
- **Auth**: Required
- **Body**:
```json
{
    "cidr_vpc": "10.0.0.0/16",
    "subnets": [
        "10.0.1.0/24",
        "10.0.2.0/24"
    ]
}
```
- **Response**: Created VPC details

### Step 5: Run Requests

1. Select a request from the collection
2. Ensure the `Authorization` header is set with `Bearer {{id_token}}`
3. Click **Send**
4. Review the response

### Token Expiration

ID tokens expire after **1 hour** (3600 seconds). If you receive a `401 Unauthorized` error:

1. Generate a new token using the `initiate-auth` command
2. Update the `id_token` variable in Postman
3. Retry the request

## 6. Project Structure

```
d:\my-work\projects\aws_challenge_assignment\
├── terraform/
│   ├── main.tf                          # Main configuration
│   ├── variables.tf                     # Input variables
│   ├── outputs.tf                       # Output values
│   ├── versions.tf                      # Provider versions
│   └── modules/
│       ├── api_gateway/                 # API Gateway module
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── cognito/                     # Cognito module
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── lambda/                      # Lambda module
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── dynamodb/                    # DynamoDB module
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
├── lambda/
│   ├── handler.py                       # Lambda function code
│   └── requirements.txt                 # Python dependencies
├── VPC Management API.postman_collection.json
└── README.md
```

## 7. Cleanup

To destroy all created resources and avoid charges:

```bash
cd terraform
terraform destroy
```

Type `yes` when prompted.

**Note**: This will delete:
- API Gateway
- Lambda functions
- DynamoDB table (and all data)
- Cognito User Pool
- All associated resources

The S3 state bucket must be deleted manually:
```bash
aws s3 rb s3://415699578050-us-east-1-state-bucket --force
```

## 8. Troubleshooting

### Issue: 401 Unauthorized Error

**Cause**: Missing or expired authentication token

**Solution**: 
1. Generate a new token using `initiate-auth` command
2. Update the `Authorization` header in Postman
3. Ensure the header format is correct

### Issue: Terraform State Bucket Error

**Cause**: Bucket name already exists or not unique

**Solution**: 
- Use your AWS Account ID in the bucket name
- Ensure the bucket name is globally unique
- Check if the bucket already exists: `aws s3 ls | grep state-bucket`

### Issue: Cognito User Creation Failed

**Cause**: Password doesn't meet policy requirements

**Solution**: 
- Password must be at least 8 characters
- Include uppercase, lowercase, numbers, and symbols
- Example: `DemoPass123!`

### Issue: API Gateway Returns 403 Forbidden

**Cause**: Invalid or missing Cognito authorizer

**Solution**: 
- Verify the `Authorization` header contains a valid ID token
- Check that the token hasn't expired
- Ensure the Cognito authorizer is properly configured

## 9. Security Best Practices

- ✅ API authenticated with Cognito User Pools
- ✅ Lambda functions use least-privilege IAM roles
- ✅ DynamoDB encryption at rest enabled
- ✅ API Gateway endpoint is VPC-enabled (optional)
- ✅ CloudWatch logging enabled for audit trails
- ✅ Terraform state stored in S3 with versioning

## 10. Additional Resources

- [AWS API Gateway Documentation](https://docs.aws.amazon.com/apigateway/)
- [AWS Cognito User Pools](https://docs.aws.amazon.com/cognito/latest/developerguide/cognito-user-identity-pools.html)
- [AWS Lambda Python](https://docs.aws.amazon.com/lambda/latest/dg/lambda-python.html)
- [AWS DynamoDB](https://docs.aws.amazon.com/dynamodb/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 11. Reviewer Notes

This assignment demonstrates:
- ✅ Infrastructure as Code using Terraform
- ✅ Serverless architecture design
- ✅ RESTful API implementation
- ✅ Authentication and authorization
- ✅ NoSQL database integration
- ✅ AWS best practices
- ✅ Complete documentation

**Total Setup Time**: ~10-15 minutes  
**Deployment Time**: ~5-10 minutes

For questions or issues, please review the troubleshooting section or check CloudWatch logs.





