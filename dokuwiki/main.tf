
variable "credentials_file" {
  default = "../secrets/cis-91.key"
}

variable "project" {
  default = "zer0-326618"
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  region      = var.region
  zone        = var.zone
  project     = var.project
}

resource "google_compute_network" "vpc_network" {
  name = "cis91-network"
}

resource "google_compute_disk" "backup-disk" {
  name = "backup-disk"
  size = 100
  type = "pd-ssd"
  zone = var.zone
}

resource "google_storage_bucket" "static-state" {
  name          = "zer0-bucket-dokuwiki"
  location      = "US"
  force_destroy = true
}

resource "google_service_account" "project1-service-account" {
  account_id   = "project1-service-account"
  display_name = "project1-service-account"
  description  = "Service account for project1"
}

resource "google_project_iam_member" "project_member" {
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.project1-service-account.email}"
}

resource "google_compute_instance" "vm_instance" {
  name                      = "cis91"
  machine_type              = "e2-micro"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  attached_disk {
    source      = google_compute_disk.backup-disk.name
    device_name = "backup-disk"
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }

  service_account {
    email  = google_service_account.project1-service-account.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_firewall" "default-firewall" {
  name    = "default-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["22", "80"]
  }
  source_ranges = ["0.0.0.0/0"]
}

output "external-ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
