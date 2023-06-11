resource "google_storage_bucket" "remote-backend" {
  name          = "backend-bucket-iti-final-project"
  force_destroy = false
  location      = "us-east1"
  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
}
# terraform {
#  backend "gcs" {
#    bucket  = "backend-bucket-iti-final-project"
#    prefix  = "terraform/state"
#  }
# }