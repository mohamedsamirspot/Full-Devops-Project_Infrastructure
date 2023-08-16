# 2 service accounts (one for the gke cluster and one for the public instance)
resource "google_service_account" "gke-publicinstance-sa" {
  count      = length(var.accounts)
  account_id = var.accounts[count.index]
}

resource "google_project_iam_member" "assign-roles-to-gke-sa" {
  count   = length(var.gke-sa-roles)
  project = var.project_id
  role    = var.gke-sa-roles[count.index]
  member  = "serviceAccount:${google_service_account.gke-publicinstance-sa[0].email}"
}

resource "google_project_iam_member" "assign-roles-to-publicinstance-sa" {
  project = var.project_id
  role    = var.gke-sa-roles[1]
  member  = "serviceAccount:${google_service_account.gke-publicinstance-sa[1].email}"
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