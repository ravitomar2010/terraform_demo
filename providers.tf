provider "google" {
  credentials = file(var.credentials)
  project     = var.project
  region      = "us-central1"
}

provider "google-beta" {
  credentials = file(var.credentials)
  project     = var.project
  region      = "us-central1"
}