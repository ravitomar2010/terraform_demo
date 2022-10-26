terraform {
  backend "gcs" {
    bucket  = "tfstate-demoterraform"
    prefix  = "terraform/state"
    credentials = "cred.json"
  }
}