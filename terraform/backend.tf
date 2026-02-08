terraform {
  backend "s3" {
    bucket       = "415699578050-ap-south-1-state-bucket"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true 
  }
}