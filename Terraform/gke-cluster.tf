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
    preemptible     = true
    machine_type    = "e2-standard-4" # (4 vCPU, 16 GB memory)
    disk_type       = "pd-standard"   # Standard persistent disk
    disk_size_gb    = 30
    image_type      = "ubuntu_containerd"
    service_account = google_service_account.gke-publicinstance-sa[0].email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"] # Allow full access to all Cloud APIs
  }
}

resource "google_container_cluster" "private-cluster" {
  name       = "private-cluster"
  network    = google_compute_network.myvpc.name
  subnetwork = google_compute_subnetwork.subnets[1].name

  remove_default_node_pool = true
  initial_node_count       = 1
  master_authorized_networks_config { # It specifies the list of CIDR blocks that are allowed to access the cluster's Kubernetes master. In this case, it includes a single CIDR block specified by var.cidr_ranges[0] and assigns it a display name from var.subnet_names[0].
    cidr_blocks {
      cidr_block   = var.cidr_ranges[0]
      display_name = var.subnet_names[0]
    }
  }
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }
  ip_allocation_policy {
    # ip_allocation_policy will be allocated automatically and i should put this block
  }
}

# #-----------------------------------master_ipv4_cidr_block--------------------------------
# # Network IP address range: Ensure that the CIDR block you provide for the master IP address range is within the IP address range of your VPC network. This ensures that the master's IP address is part of the same network as the nodes.
# # Non-overlapping: Ensure that the CIDR block for the master IP address range does not overlap with any existing IP address ranges within your VPC network or other subnets.
# # Subnet availability: Confirm that the chosen CIDR block is not already allocated to an existing subnet within your VPC network. Subnets and the master IP address range should have distinct and non-overlapping IP address ranges.
# #-----------------------------------node_count vs full-devops-proj-bastian-host-key.pubinitial_node_count----------------------
# # node_count is used to define the number of nodes within a specific node pool, 
# # while initial_node_count is used to define the initial number of nodes for the entire cluster,
# # including any default node pools (which can be removed) and any custom node pools defined.