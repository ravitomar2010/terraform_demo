resource "google_compute_network" "vpc_network" {
  name                    = "${var.assignment}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "public-subnetwork" {
  name          = "${var.assignment}-web-subnet"
  ip_cidr_range = "10.0.0.0/28"
  region        = var.region
  network       = google_compute_network.vpc_network.name
}

data "google_compute_zones" "available" {
}

data "template_file" "init" {
  template = file("nginx.sh")
}

resource "google_compute_instance_template" "server" {
  name         = "${var.assignment}-webtemplate"
  machine_type = "f1-micro"
  provider     = google-beta
  tags         = ["web"]
  region       = var.region
  labels = {name = "webserver"}

  disk {
    source_image = data.google_compute_image.debian.self_link
  }

  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.public-subnetwork.name
    access_config {
      # Ephemeral IP - leaving this block empty will generate a new external IP and assign it to the machine
    }
  }

  metadata = {
    ssh-keys = "${var.gce_ssh_user}:${file(var.gce_ssh_pub_key_file)}"
  }

  metadata_startup_script = data.template_file.init.rendered

  service_account {
    scopes = ["cloud-platform"]
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

data "google_compute_image" "debian" {
  family  = "debian-10"
  project = "debian-cloud"
}

resource "google_compute_instance_group_manager" "mig" {
  count = length(data.google_compute_zones.available.names)
  name               = "web-server-${count.index}"
  version {
    instance_template  = google_compute_instance_template.server.self_link

  }  
  base_instance_name = "web-${count.index}"
  zone               = data.google_compute_zones.available.names[count.index]
  target_size        = 1
  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_autoscaler" "foobar" {
  count = length(data.google_compute_zones.available.names)
  name   = "web-autoscalar-${count.index}"
  zone   = data.google_compute_zones.available.names[count.index]
  target = google_compute_instance_group_manager.mig[count.index].id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 1
    cooldown_period = 60

    cpu_utilization {
      target = 0.5
    }
  }
}

resource "google_compute_http_health_check" "healthcheck" {
  name         = "web-healthcheck-${var.assignment}"
  project      = var.project
  port         = 80
  request_path = "/"
}

resource "google_compute_backend_service" "backends" {

  name            = "backend-${var.assignment}"
  port_name       = "http"
  project         = var.project
  protocol        = "HTTP"
  security_policy = google_compute_security_policy.policy.name
  health_checks   = [google_compute_http_health_check.healthcheck.id]
  enable_cdn             = "false"

  # backend block
  dynamic backend {
    for_each = google_compute_instance_group_manager.mig
    content {
    group                 = backend.value["instance_group"]
    balancing_mode        = "UTILIZATION"
    max_rate_per_instance = 50
    }
  }
}

resource "google_compute_url_map" "url_map" {
  name            = "${var.assignment}-urlmap"
  project         = var.project
  default_service = google_compute_backend_service.backends.id
}

resource "google_compute_target_http_proxy" "proxy" {
  name    = "${var.assignment}-proxy"
  project = var.project
  url_map = google_compute_url_map.url_map.id
}

resource "google_compute_global_forwarding_rule" "global_fwd_rule" {
  name                  = "${var.assignment}-forwardngrule"
  project               = var.project
  target                = google_compute_target_http_proxy.proxy.id
  ip_protocol           = "TCP"
  ip_version            = "IPV4"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
}

resource "google_compute_firewall" "firewall" {
  name          = "${var.assignment}-firewallweb"
  network       = google_compute_network.vpc_network.name
  provider      = google-beta
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  allow {
    protocol = "tcp"
    ports    = ["22","80"]
  }
  source_tags = ["allow-ssh","web"]
  target_tags = ["web"]
}

resource "google_compute_security_policy" "policy" {
  name = "${var.assignment}-policy"

  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["9.9.9.0/24"]
      }
    }
    description = "These ips are allowed"
  }

  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "these ips are allowed"
  }
}

# output migselflink {
#   value       = google_compute_instance_group_manager.mig[each.key].self_link
#   description = "description"
# }
# output migid {
#   value       = for i in google_compute_instance_group_manager.mig { google_compute_instance_group_manager.mig[i] }
#   description = "description"
# }

output mig {
  value       = google_compute_instance_group_manager.mig
  description = "description"
}
