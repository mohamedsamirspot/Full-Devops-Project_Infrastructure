# public instance
resource "google_compute_instance" "public_vm" {
  name         = "public-vm"
  machine_type = var.machine_type
  tags         = ["public-vm"]

  boot_disk {
    initialize_params {
      image = var.vm_image
    }
  }
  # scratch_disk {
  #   interface = "SCSI"
  # }
  network_interface {
    network    = google_compute_network.myvpc.name
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
  provisioner "local-exec" {
    command = <<-EOT
      echo "[bastian-host]" > ../ansible-bastian_vm-preparation/inventory
      echo "${google_compute_instance.public_vm.network_interface[0].access_config[0].nat_ip}" >> ../ansible-bastian_vm-preparation/inventory
    EOT
  }
  service_account {
    email  = google_service_account.gke-publicinstance-sa[1].email
    scopes = ["cloud-platform"] # Allow full access to all Cloud APIs
  }

  #ssh-keygen -t ed25519 -C  <remote-user-name> -f <file-name>
  #ssh-keygen -t ed25519 -C spot -f /Terraform-folderpath/full-devops-proj-bastian-host-key
  # remote user this is the user to connect to the vm using ssh (ssh -i /home/spot/.ssh/full-devops-proj-bastian-host-key spot@vm-ip)
  metadata = {
    ssh-keys = file("full-devops-proj-bastian-host-key.pub")
    # file is built in function in terraform
    # "ssh-keys" = <<EOT
    #   ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGhUumonYTfWT1Kd1FjjxsNXinHoG1alvWjmNWD5w0Dh spot
    #   EOT
  }
}