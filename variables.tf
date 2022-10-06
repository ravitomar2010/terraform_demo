variable "credentials" {
  type        = string
  description = "Enter service account file path with name"
  default = "cred.json"
}

variable "project" {
  type        = string
  description = "Enter project id"
  default = "internal-interview-candidates"
}

variable region {
  type        = string
  default     = "us-central1"
  description = "enter region for you project"
}

variable gce_ssh_user {
  type        = string
  default     = "testadmin"
  description = "enter ssh username"
}

variable gce_ssh_pub_key_file {
  type        = string
  default     = "pubfile.pub"
  description = "enter public key file"
}

variable assignment {
  type        = string
  default     = "ravi"
  description = "enter assignement name"
}






