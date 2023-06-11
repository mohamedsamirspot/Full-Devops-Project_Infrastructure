variable "project_id" {
  type = string
  default = "myproject-387907"
}
variable "region" {
  type = string
  default = "us-east1"
}
variable "zone" {
  # for the public vm
  type = string
  default = "us-east1-b"
}
variable "vpc_name" {
  type = string
  default = "myvpc"
}
variable "subnet_names" {
  type = list(string)
  default = ["management-subnet", "restricted-subnet"]
}
variable "cidr_ranges" {
  type = list(string)
  default = ["10.0.0.0/24","10.0.1.0/24"]
}
variable "machine_type" {
  type = string
  default = "e2-medium"
}
variable "vm_image" {
  type = string
  default = "debian-cloud/debian-11"
}
variable "accounts" {
    type = list(string)
    default = ["gke-sa", "instance-sa"]
}
variable "gke-sa-roles" {
    type = list(string)
    default = ["roles/storage.admin", "roles/container.admin"]
}
# roles/container.admin --> Kubernetes Engine Admin
# roles/storage.admin --> Storage Admin