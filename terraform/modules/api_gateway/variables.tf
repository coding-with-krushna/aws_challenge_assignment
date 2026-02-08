variable "api_name" {
  description = "The name of the REST API"
  type        = string
}

variable "integration_ids" {
  description = "List of integration IDs to trigger redeployment"
  type        = list(string)
  default     = []
}

variable "authorizer_id" {
  type        = string
  description = "The ID of the Cognito Authorizer"
  default     = "" # Optional if you want some methods unprotected
}