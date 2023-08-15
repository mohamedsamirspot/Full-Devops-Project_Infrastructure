#!/bin/bash


#------------------------- GCP Infrastructure Creation using Terraform ---------------------------------
cd Terraform

# Store the original content of the Terraform configuration file
original_content=$(cat remote-backend.tf)

# Comment out the backend block from the remote-backend.tf file
echo "$original_content" | awk '/^terraform {/,/^\s*}$/ {$0 = "# " $0} {print}' > remote-backend.tf

# Run terraform init and creating the backend bucket
terraform init
terraform apply -target=google_storage_bucket.remote-backend --auto-approve

# Restore the original content
echo "$original_content" > remote-backend.tf

# Set the path to your service account key file and activate it, this if the host does not logged in to gcp using gcloud so use the svc key directly
# in my case i don't need it
SERVICE_ACCOUNT_KEY_PATH="./myproject-387907-d5bf47e25357.json"
# Activate the service account
gcloud auth activate-service-account --key-file="$SERVICE_ACCOUNT_KEY_PATH"


terraform init -upgrade
terraform apply --auto-approve

if [ $? -ne 0 ]
then
    echo "Error During Terraform Execution, Failed Run!"
    exit $?
fi


#------------------------- Now preparing the bastian host using ansbible ---------------------------------
cd ..
cd ansible-bastian_vm-preparation
ansible-playbook vm-preparation.yml