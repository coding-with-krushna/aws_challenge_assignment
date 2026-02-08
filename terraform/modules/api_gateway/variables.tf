variable "api_name" {
  description = "The name of the REST API"
  type        = string
}

variable "integration_ids" {
  description = "List of integration IDs to trigger redeployment"
  type        = list(string)
  default     = []
}