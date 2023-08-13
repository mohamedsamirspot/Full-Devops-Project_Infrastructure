provider "google" {
  credentials = file("myproject-387907-d5bf47e25357.json")
  project = var.project_id
  region  = var.region
  zone    = var.zone 
}

# 2 service accounts (one for the gke cluster and one for the public instance)
resource "google_service_account" "gke-publicinstance-sa" {
  count = length(var.accounts)
  account_id   = var.accounts[count.index]
}

resource "google_project_iam_member" "assign-roles-to-gke-sa" {
  count = length(var.gke-sa-roles)
  project = var.project_id
  role    = var.gke-sa-roles[count.index] 
  member  = "serviceAccount:${google_service_account.gke-publicinstance-sa[0].email}"
}

resource "google_project_iam_member" "assign-roles-to-publicinstance-sa" {
  project = var.project_id
  role = var.gke-sa-roles[1] 
  member = "serviceAccount:${google_service_account.gke-publicinstance-sa[1].email}"
}

# resource "google_project_iam_member" "roles/storage.admin" {
#   project = var.project_id
#   role = "roles/storage.admin"
#   member = "serviceAccount:${google_service_account.gke-publicinstance-sa[0].email}"
# }

# resource "google_project_iam_member" "roles/container.admin" {
#   project = var.project_id
#   role = "roles/container.admin"
#   member = "serviceAccount:${google_service_account.gke-publicinstance-sa[0].email}"
# }

# the vpc
resource "google_compute_network" "myvpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

# firewall rules
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.myvpc.name
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["public-vm"]
  source_ranges = ["0.0.0.0/0"]
}
resource "google_compute_firewall" "allow_all_egress" {
  name        = "allow-all-egress"
  network     = google_compute_network.myvpc.name
  direction   = "EGRESS"
  target_tags = ["public-vm"]
  destination_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"  # Allow all protocols
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

# public instance
resource "google_compute_instance" "public_vm" {
  name         = "public-vm"
  machine_type = var.machine_type 
  tags         = ["public-vm"]

  boot_disk {
    initialize_params{
      image = var.vm_image
    }
  }
  # scratch_disk {
  #   interface = "SCSI"
  # }
  network_interface {
    network = google_compute_network.myvpc.name
    subnetwork = google_compute_subnetwork.subnets[0].name
    # by default no public key assigned
    #     access_config {
    #    Optional: Uncomment the line below to assign an ephemeral public IP
    #    nat_ip = "ephemeral"
    # }
    access_config {
      // This will assign a public IP to the VM
    }
  }
  
  service_account {
    email  = google_service_account.gke-publicinstance-sa[1].email
    scopes = ["cloud-platform"] # Allow full access to all Cloud APIs
  }

  #ssh-keygen -t ed25519 -C  <remote-user-name> -f <file-name>
  # remote user this is the user to connect to the vm using ssh (ssh -i full-devops-proj-bastian-host-key spot@34.74.222.37)
    metadata = {
    "ssh-keys" = <<EOT
      ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGhUumonYTfWT1Kd1FjjxsNXinHoG1alvWjmNWD5w0Dh spot
      EOT
   }
}

# cloud router for the nat
resource "google_compute_router" "myrouter" {
  name    = "my-nat-cloud-router"
  network = google_compute_network.myvpc.id
}

# cloud nat
resource "google_compute_router_nat" "mynat" {
  name                               = "my-cloud-nat"
  router                             = google_compute_router.myrouter.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  # source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES" if want all subnets


  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS" # to the private cluster subnet only worker nodes to get images from doocker hub
  subnetwork {
    name                    = google_compute_subnetwork.subnets[1].id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }



}

# cluster creation
resource "google_container_node_pool" "privatecluster-node-pool" {
  name       = "my-privatecluster-node-pool"
  cluster    = google_container_cluster.private-cluster.name
  node_count = 2
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
 
  node_config {
    preemptible  = true
    machine_type = "e2-standard-4" # (4 vCPU, 16 GB memory)
    disk_type    = "pd-standard" # Standard persistent disk
    disk_size_gb = 30
    image_type   = "ubuntu_containerd"
    service_account = google_service_account.gke-publicinstance-sa[0].email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"] # Allow full access to all Cloud APIs
  }
}

resource "google_container_cluster" "private-cluster"{
  name     = "private-cluster"
  network = google_compute_network.myvpc.name
  subnetwork = google_compute_subnetwork.subnets[1].name

  remove_default_node_pool = true
  initial_node_count       = 1
  master_authorized_networks_config { # It specifies the list of CIDR blocks that are allowed to access the cluster's Kubernetes master. In this case, it includes a single CIDR block specified by var.cidr_ranges[0] and assigns it a display name from var.subnet_names[0].
    cidr_blocks {
        cidr_block = var.cidr_ranges[0]
        display_name = var.subnet_names[0]
    }
  }
  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = true
    master_ipv4_cidr_block = "172.16.0.0/28"
  }
  ip_allocation_policy {
      # ip_allocation_policy will be allocated automatically and i should put this block
  }
}

#-----------------------------------master_ipv4_cidr_block--------------------------------
# Network IP address range: Ensure that the CIDR block you provide for the master IP address range is within the IP address range of your VPC network. This ensures that the master's IP address is part of the same network as the nodes.
# Non-overlapping: Ensure that the CIDR block for the master IP address range does not overlap with any existing IP address ranges within your VPC network or other subnets.
# Subnet availability: Confirm that the chosen CIDR block is not already allocated to an existing subnet within your VPC network. Subnets and the master IP address range should have distinct and non-overlapping IP address ranges.
#-----------------------------------node_count vs initial_node_count----------------------
# node_count is used to define the number of nodes within a specific node pool, 
# while initial_node_count is used to define the initial number of nodes for the entire cluster,
# including any default node pools (which can be removed) and any custom node pools defined.
