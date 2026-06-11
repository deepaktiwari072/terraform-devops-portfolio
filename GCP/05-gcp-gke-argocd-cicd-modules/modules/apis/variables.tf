variable "required_apis" {
    description = "List of GCP APIs that must be enabled for this project."
    type = list(string)
}