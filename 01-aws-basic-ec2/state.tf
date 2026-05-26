terraform {
  backend "s3" {
    region       = "us-west-2"
    bucket       = "terraform-tfstate-deepak"
    key          = "aws/us-west-2/terraform-tfstate-deepak/01-aws-basic-ec2/terraform.tfstate"
    profile      = "sso-dev"
    encrypt      = true
    use_lockfile = true

  }
}