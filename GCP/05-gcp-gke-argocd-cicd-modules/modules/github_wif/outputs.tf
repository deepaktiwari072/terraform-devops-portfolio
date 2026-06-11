output "terraform_service_account_email" {
  description = "Email of the Terraform deployer service account impersonated by GitHub Actions."
  value       = google_service_account.terraform_deployer.email
}

output "workload_identity_provider" {
  description = "Full Workload Identity Provider resource name used by GitHub Actions."
  value       = google_iam_workload_identity_pool_provider.github.name
}