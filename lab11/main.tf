
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

resource "google_compute_network" "my-network" {
  name                    = "custom-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "custom-subnet1" {
  name          = "test-subnet1"
  ip_cidr_range = "10.5.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.my-network.id
}

resource "google_compute_subnetwork" "custom-subnet2" {
  name          = "test-subnet2"
  ip_cidr_range = "10.6.0.0/24"
  region        = "asia-east1"
  network       = google_compute_network.my-network.id
}

resource "google_compute_subnetwork" "custom-subnet3" {
  name          = "test-subnet3"
  ip_cidr_range = "10.7.0.0/24"
  region        = "europe-west1"
  network       = google_compute_network.my-network.id
}

resource "google_compute_instance" "vm_instance" {
  name         = "cis91"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
    }
  }
}

resource "google_compute_firewall" "default-firewall" {
  name    = "default-firewall"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["22", "80", "3000", "5000"]
  }
  source_ranges = ["0.0.0.0/0"]
}

output "external-ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
