resource "aws_api_gateway_rest_api" "this" {
  name = var.api_name
}

# Resource: /v1
resource "aws_api_gateway_resource" "v1" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "v1"
}

# Resource: /v1/vpc
resource "aws_api_gateway_resource" "vpc" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "vpc"
}

# Methods: GET and POST
resource "aws_api_gateway_method" "methods" {
  for_each      = toset(["GET", "POST"])
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.vpc.id
  http_method   = each.value
  authorization = "NONE"
}

# Deployment
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  
  # Trigger redeploy when methods change
  triggers = {
    redeployment = sha1(jsonencode(var.integration_ids))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "prod"
}