provider "google" {
  credentials = file("myproject-387907-d5bf47e25357.json") # on my case i don't need this as i already connected to gcp using gcloud through my local machine
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

# the vpc
resource "google_compute_network" "myvpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

# firewall rules
resource "google_compute_firewall" "allow_ssh" {
  name      = "allow-ssh"
  network   = google_compute_network.myvpc.name
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["public-vm"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_all_egress" {
  name               = "allow-all-egress"
  network            = google_compute_network.myvpc.name
  direction          = "EGRESS"
  target_tags        = ["public-vm"]
  destination_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all" # Allow all protocols
  }

  description = "Allow all outbound traffic"
}



# 2 subnets
resource "google_compute_subnetwork" "subnets" {
  count         = length(var.cidr_ranges)
  name          = var.subnet_names[count.index]
  ip_cidr_range = var.cidr_ranges[count.index]
  network       = google_compute_network.myvpc.id
}



# cloud router for the nat
resource "google_compute_router" "myrouter" {
  name    = "my-nat-cloud-router"
  network = google_compute_network.myvpc.id
}

# cloud nat
resource "google_compute_router_nat" "mynat" {
  name                   = "my-cloud-nat"
  router                 = google_compute_router.myrouter.name
  nat_ip_allocate_option = "AUTO_ONLY"
  # source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES" if want all subnets


  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS" # to the private cluster subnet only worker nodes to get images from doocker hub
  subnetwork {
    name                    = google_compute_subnetwork.subnets[1].id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}