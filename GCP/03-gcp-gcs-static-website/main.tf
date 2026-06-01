locals {
  name_prefix = "${var.gcp_project_name}-${var.environment}"

}

resource "google_storage_bucket" "site" {
  location                    = var.gcp_region
  name                        = var.bucket_name
  uniform_bucket_level_access = true
  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }

}

resource "google_storage_bucket_object" "index" {
  bucket  = google_storage_bucket.site.name
  name    = "index.html"
  source  = "${path.module}/index.html"
  content_type = "text/html"

}

resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.site.name
  role   = "roles/storage.objectViewer"
   member = "allUsers"

}