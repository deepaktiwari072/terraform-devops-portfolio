terraform {
  backend "gcs" {
    bucket = "gcp-terraform-dev"
    prefix = "terraform/state"
       
  }
}