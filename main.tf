module ha_region {
  source = "./modules/ha_region"
  region = "europe-west1"
  gce_ssh_user = "testadmin1"
  gce_ssh_pub_key_file = "pubfile.pub"
  assignment = "ravidemo"
}

module ha_region1 {
  source = "./modules/ha_region"
  region = "us-west1"
  gce_ssh_user = "testadmin1"
  gce_ssh_pub_key_file = "pubfile.pub"
  assignment = "ravidemo"
}
