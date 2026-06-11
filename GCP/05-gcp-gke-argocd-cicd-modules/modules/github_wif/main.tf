# This service account is the identity GitHub Actions will impersonate.
# GitHub does not receive a JSON key. Instead, GitHub receives a short-lived
# token through Workload Identity Federation and uses that token to act as this
# service account.
resource "google_service_account" "terraform_deployer" {
  project      = var.gcp_project_id
  account_id   = var.service_account_id
  display_name = "Terraform deployer for ${var.name_prefix}"
  description  = "Service account impersonated by GitHub Actions through Workload Identity Federation."
}

# This grants project-level IAM roles to the Terraform deployer service account.
# for_each loops over var.terraform_roles and creates one IAM binding per role.
# each.value is the current role name, for example "roles/container.admin".
resource "google_project_iam_member" "terraform_roles" {
  for_each = toset(var.terraform_roles)

  project = var.gcp_project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform_deployer.email}"
}

# Workload Identity Pool is the trust container in GCP.
# It groups external identities, such as GitHub Actions OIDC identities.
resource "google_iam_workload_identity_pool" "github" {
  project                   = var.gcp_project_id
  workload_identity_pool_id = var.workload_identity_pool_id
  display_name              = "GitHub Actions Pool"
  description               = "Allows selected GitHub repositories to authenticate to GCP using OIDC."
}

# Workload Identity Provider defines which external identity provider GCP trusts.
# Here, the trusted issuer is GitHub Actions OIDC:
# https://token.actions.githubusercontent.com
resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.gcp_project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.workload_identity_provider_id

  display_name = "GitHub Actions Provider"
  description  = "OIDC provider that trusts tokens issued by GitHub Actions."

  # attribute_mapping maps fields from GitHub's OIDC token into GCP attributes.
  # These mapped attributes can then be used in conditions and IAM bindings.
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # GitHub Actions OIDC issuer URL.
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  # This condition restricts authentication to one GitHub repo and branch.
  # Example allowed identity:
  # repository = "deepak/my-repo"
  # ref        = "refs/heads/main"
  attribute_condition = "attribute.repository == \"${var.github_owner}/${var.github_repo}\" && attribute.ref == \"refs/heads/${var.github_branch}\""
}

# This binding allows the selected GitHub repository to impersonate the
# Terraform deployer service account.
#
# Important:
# roles/iam.workloadIdentityUser does not grant GCP project permissions by itself.
# It only allows the external GitHub identity to act as this service account.
# The actual GCP permissions come from google_project_iam_member.terraform_roles.
resource "google_service_account_iam_member" "github_can_impersonate" {
  service_account_id = google_service_account.terraform_deployer.name
  role               = "roles/iam.workloadIdentityUser"

  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_owner}/${var.github_repo}"
}