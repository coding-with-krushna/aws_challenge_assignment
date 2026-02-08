# AWS VPC API Gateway Challenge

This project demonstrates how to set up a private API Gateway integrated with AWS Lambda, accessible only from within a VPC using VPC endpoints.

## Architecture Overview

- **VPC**: Custom VPC with private subnets
- **API Gateway**: Private REST API accessible only via VPC endpoint
- **Lambda Function**: Backend function that processes requests
- **VPC Endpoint**: Interface endpoint for API Gateway access
- **Security Groups**: Control access between components

## Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.0
- Python 3.9 or later
- Postman (for API testing)
- AWS CLI configured with credentials

## Project Structure

```
.
├── terraform/
│   ├── main.tf              # Main Terraform configuration
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   └── versions.tf          # Provider versions
├── lambda/
│   └── handler.py           # Lambda function code
├── vpc_api_collection.json  # Postman collection for testing
└── README.md               # This file
```

## Setup Instructions

### Step 1: Clone the Repository

```bash
cd d:\my-work\projects\aws_challenge_assignment
```

### Step 2: Review and Update Variables

Edit `terraform/variables.tf` or create a `terraform.tfvars` file with your desired values:

```hcl
aws_region = "us-east-1"
project_name = "vpc-api-challenge"
vpc_cidr = "10.0.0.0/16"
```

### Step 3: Initialize Terraform

```bash
cd terraform
terraform init
```

### Step 4: Plan the Infrastructure

```bash
terraform plan
```

Review the planned resources to ensure everything looks correct.

### Step 5: Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted to confirm the deployment.

### Step 6: Note the Outputs

After successful deployment, Terraform will output important values:

```
api_endpoint = "https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/prod"
vpc_id = "vpc-xxxxxxxxx"
vpc_endpoint_id = "vpce-xxxxxxxxx"
lambda_function_name = "vpc-api-challenge-lambda"
```

Save these values for testing.

## Testing with Postman

### Using the VPC API Collection

This project includes a Postman collection (`vpc_api_collection.json`) to test the API Gateway.

#### Step 1: Import the Collection

1. Open Postman
2. Click **Import** button (top-left corner)
3. Select **File** tab
4. Navigate to `d:\my-work\projects\aws_challenge_assignment\vpc_api_collection.json`
5. Click **Open** to import

#### Step 2: Configure Environment Variables

Create a new environment in Postman with the following variables:

| Variable Name | Value | Description |
|--------------|-------|-------------|
| `api_endpoint` | `https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/prod` | From Terraform output |
| `aws_region` | `us-east-1` | Your AWS region |

To set up the environment:
1. Click the **Environments** tab (left sidebar)
2. Click **+** to create a new environment
3. Name it "VPC API Environment"
4. Add the variables above
5. Click **Save**
6. Select this environment from the dropdown (top-right)

#### Step 3: Configure AWS Signature Authentication

For each request in the collection:

1. Go to the **Authorization** tab
2. Select **AWS Signature** as the type
3. Enter your AWS credentials:
   - **AccessKey**: Your AWS access key
   - **SecretKey**: Your AWS secret key
   - **AWS Region**: `{{aws_region}}`
   - **Service Name**: `execute-api`

#### Step 4: Available Requests

The collection includes the following requests:

1. **GET /hello** - Basic health check
   - URL: `{{api_endpoint}}/hello`
   - Expected Response: `{"message": "Hello from VPC Lambda!"}`

2. **POST /data** - Submit data to Lambda
   - URL: `{{api_endpoint}}/data`
   - Body: `{"key": "value"}`
   - Expected Response: Processed data response

3. **GET /info** - Get API information
   - URL: `{{api_endpoint}}/info`
   - Expected Response: API metadata

#### Step 5: Run the Requests

1. Select a request from the collection
2. Click **Send**
3. View the response in the lower panel

#### Important Notes for VPC Testing

⚠️ **Access Limitation**: Since this is a **private API Gateway**, it is only accessible from within the VPC:

- **Direct Access**: Requests from your local machine will **fail** unless you have VPN/Direct Connect to the VPC
- **Recommended Testing Approaches**:
  1. **EC2 Instance**: Launch an EC2 instance in the same VPC and install Postman/curl
  2. **AWS Cloud9**: Use Cloud9 IDE in the VPC
  3. **VPN Connection**: Set up AWS Client VPN or Site-to-Site VPN
  4. **Bastion Host**: Use a bastion host with port forwarding

#### Testing from EC2 Instance

```bash
# SSH into EC2 instance in the VPC
ssh -i your-key.pem ec2-user@<ec2-public-ip>

# Install curl (if not present)
sudo yum install curl -y

# Test the API
curl -X GET https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/prod/hello

# With AWS CLI signing
aws apigateway test-invoke-method \
  --rest-api-id xxxxxxxxxx \
  --resource-id xxxxxxxxxx \
  --http-method GET \
  --path-with-query-string "/hello"
```

## Viewing Logs

### Lambda Logs

```bash
aws logs tail /aws/lambda/vpc-api-challenge-lambda --follow
```

### API Gateway Logs

```bash
aws logs tail API-Gateway-Execution-Logs_<api-id>/prod --follow
```

## Cleanup

To destroy all created resources:

```bash
cd terraform
terraform destroy
```

Type `yes` when prompted to confirm destruction.

## Troubleshooting

### Issue: API Returns 403 Forbidden

**Cause**: Accessing private API from outside the VPC

**Solution**: Ensure you're testing from within the VPC or through a VPN connection

### Issue: VPC Endpoint Connection Failed

**Cause**: Security group or route table misconfiguration

**Solution**: 
- Verify security groups allow HTTPS (port 443)
- Check route tables are associated with subnets
- Ensure VPC endpoint policy allows API Gateway access

### Issue: Lambda Function Timeout

**Cause**: Lambda not responding within configured timeout

**Solution**:
- Check Lambda logs in CloudWatch
- Increase timeout in `terraform/main.tf`
- Verify Lambda has required permissions

## Security Considerations

- API Gateway is **private** and only accessible from VPC
- Security groups restrict access to specific ports
- Lambda execution role has minimal required permissions
- VPC endpoints use AWS PrivateLink for secure communication
- Enable CloudWatch logging for audit trails

## Additional Resources

- [AWS API Gateway VPC Links](https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-private-apis.html)
- [VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## License

This project is for educational purposes.





