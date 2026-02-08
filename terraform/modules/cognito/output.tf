output "user_pool_arn" {
  description = "The ARN of the User Pool (used for API Gateway Authorizer)"
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_id" {
  description = "The ID of the User Pool (used for CLI user creation)"
  value       = aws_cognito_user_pool.this.id
}

output "client_id" {
  description = "The ID of the App Client (used for CLI login)"
  value       = aws_cognito_user_pool_client.this.id
}