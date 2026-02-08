output "cognito_user_pool_id" {
  value = module.auth.user_pool_id
}

output "cognito_client_id" {
  value = module.auth.client_id
}

output "api_url" {
  description = "The base URL for your VPC API"
  value       = "${module.api.base_url}/v1/vpc" 
}