module "api" {
  source          = "./modules/api_gateway"
  api_name        = "vpc-manager-api"
  integration_ids = [for i in aws_api_gateway_integration.lambda_link : i.id]
  authorizer_id   = aws_api_gateway_authorizer.cognito_auth.id
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

module "auth" {
  source         = "./modules/cognito"
  user_pool_name = "vpc-api-auth"
}

# Integration for both GET and POST
resource "aws_api_gateway_integration" "lambda_link" {
  for_each                = toset(["GET", "POST"])
  rest_api_id             = module.api.api_id
  resource_id             = module.api.resource_id
  http_method             = each.value
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda.lambda_invoke_arn
}

# API Gateway Authorizer using the module output
resource "aws_api_gateway_authorizer" "cognito_auth" {
  name          = "cognito_auth"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = module.api.api_id
  provider_arns = [module.auth.user_pool_arn]
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
  role = module.lambda.lambda_role_name

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
          "ec2:CreateTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# Quota and throttling to control costs
resource "aws_api_gateway_usage_plan" "vpc_api_plan" {
  name         = "vpc-api-usage-plan"
  description  = "Limits total requests to control costs"

  api_stages {
    api_id = module.api.api_id
    stage  = "prod"
  }

  # Hard cap on total requests
  quota_settings {
    limit  = 1000    # Max 1000 requests
    period = "MONTH" # Per month
  }

  # Speed limit
  throttle_settings {
    burst_limit = 10
    rate_limit  = 5
  }
}