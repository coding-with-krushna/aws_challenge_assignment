variable "user_pool_name" {
  type        = string
  description = "Name of the Cognito User Pool"
}

variable "tags" {
  type    = map(string)
  default = {}
}