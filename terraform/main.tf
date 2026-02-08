module "api" {
  source   = "./modules/api_gateway"
  api_name = "vpc-manager-api"

  # This fixes the error by ensuring integrations exist before deployment
  integration_ids = [for i in aws_api_gateway_integration.lambda_link : i.id]
}

module "lambda" {
  source        = "./modules/lambda"
  function_name = "vpc-backend-handler"
  dynamo_table_name = module.vpc_registry.table_name
}

module "vpc_registry" {
  source     = "./modules/dynamodb"
  table_name = "vpc-registry"
  hash_key   = "vpc_id"

  attributes = [
    {
      name = "vpc_id"
      type = "S"
    }
  ]

  tags = {
    Environment = "dev"
    Project     = "vpc-api-challenge"
  }
}

# Integration for both GET and POST
resource "aws_api_gateway_integration" "lambda_link" {
  for_each                = toset(["GET", "POST"])
  rest_api_id             = module.api.api_id
  resource_id             = module.api.resource_id
  http_method             = each.value
  integration_http_method = "POST" # Lambda is always called via POST
  type                    = "AWS_PROXY"
  uri                     = module.lambda.lambda_invoke_arn
}

# Permission: Allow API Gateway to call Lambda
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda.lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api.execution_arn}/*/*"
}

# Permission for Lambda to access DynamoDB
resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "lambda-dynamodb-access"
  role = module.lambda.lambda_role_name # Make sure your lambda module outputs the role name!

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:Scan"]
        Effect   = "Allow"
        Resource = module.vpc_registry.table_arn
      }
    ]
  })
}

# Permission for Lambda to create VPCs and Subnets
resource "aws_iam_role_policy" "lambda_vpc_admin" {
  name = "lambda-vpc-creation-policy"
  # This must match the output name of the role from your lambda module
  role = module.lambda.lambda_role_name 

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateVpc",
          "ec2:CreateSubnet",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:CreateTags" # Needed if your code adds names/tags to the VPC
        ]
        Resource = "*"
      }
    ]
  })
}