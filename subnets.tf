resource "google_compute_subnetwork" "private1" {
  name                     = "private1"
  ip_cidr_range            = "10.0.0.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.vpc-network.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "k8s-pod-range"
    ip_cidr_range = "10.48.0.0/16"
  }
  secondary_ip_range {
    range_name    = "k8s-service-range"
    ip_cidr_range = "10.50.0.0/16"
  }
}

resource "google_compute_subnetwork" "private2" {
  name                     = "private2"
  ip_cidr_range            = "10.0.1.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.vpc-network.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "k8s-pod-range"
    ip_cidr_range = "10.49.0.0/16" # Updated range for private2
  }
  secondary_ip_range {
    range_name    = "k8s-service-range"
    ip_cidr_range = "10.51.0.0/16" # Updated range for private2
  }
}

resource "google_compute_subnetwork" "private3" {
  name                     = "private3"
  ip_cidr_range            = "10.2.0.0/24"
  region                   = "us-central1"
  network                  = google_compute_network.vpc-network.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "k8s-pod-range"
    ip_cidr_range = "10.52.0.0/16"
  }
  secondary_ip_range {
    range_name    = "k8s-service-range"
    ip_cidr_range = "10.53.0.0/16"
  }
}
