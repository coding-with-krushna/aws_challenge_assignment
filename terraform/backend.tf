terraform {
  backend "s3" {
    bucket       = "415699578050-us-east-1-state-bucket"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true 
  }
}