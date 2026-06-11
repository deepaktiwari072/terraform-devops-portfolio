# for_each creates one google_project_service resource for every API in var.required_apis.
# toset() converts the list into a set because for_each works best with maps or sets.
# each.value is the current API name, for example "container.googleapis.com".
resource "google_project_service" "apis" {
  for_each = toset(var.required_apis)

  service            = each.value
  disable_on_destroy = false
}


