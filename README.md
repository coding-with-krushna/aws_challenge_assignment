# aws_challenge_assignment

# AWS Configure

# Setup terraform state file S3 bucket and dynamo db
aws s3api create-bucket --bucket 415699578050-us-east-1-state-bucket --region us-east-1

# Terraform Init
terraform init

# Terraform Plan
terraform plan

# Terraform Apply
terraform apply -auto-approve


