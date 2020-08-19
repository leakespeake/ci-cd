# create a Google Compute Engine VM instance
resource "google_compute_instance" "vm_instance" {
  name         = "terraform-gcp-vm-01"
  machine_type = "f1-micro"
  project      = "test-project-01-286706"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    #network = "default"                                          # a default network is created for all GCP projects
    network = google_compute_network.vpc_network.self_link        # link resources via 'self_link' (a unique reference to that resource)
    access_config {
    }
  }
}

# create a VPC network resource with a subnetwork in each region
resource "google_compute_network" "vpc_network" {
  name                    = "terraform-gcp-network-01"
  project                 = "test-project-01-286706"
  auto_create_subnetworks = "true"
}