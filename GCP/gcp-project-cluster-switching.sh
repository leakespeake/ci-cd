#!/bin/bash
# Easily switch between existing GCP projects and GKE clusters in your gcloud configuration
# Easily add and authenticate to new GCP projects and add their default regions and zones
# All gcloud configuration for projects and clusters confirmed upon script exit


# Function to activate an existing GCP project configuration
activate_gcp_project() {
  local project_id="$1"
  gcloud config configurations activate "$project_id"
  echo "GCP project set to: $project_id"
}

# Function to set the GKE cluster
set_gke_cluster() {
  local cluster_name="$1"
  local cluster_region="$2"
  local project_id
  project_id=$(gcloud config get-value project)
  gcloud container clusters get-credentials "$cluster_name" --project "$project_id" --region "$cluster_region"
  echo "GKE cluster set to: $cluster_name in region: $cluster_region"
}

# Function to create a new gcloud configuration for a GCP project then authenticate to it
create_gcloud_config() {
  local project_id="$1"
  gcloud config configurations create "$project_id"
  gcloud config set project "$project_id"
  echo "New gcloud configuration created for project: $project_id"
  gcloud auth login
}

# Function to set the region and zone for a new gcloud configuration
set_gcloud_region() {
  local region="$1"
  local zone
  zone="${region}-a" # Assuming zone is derived from region, e.g., us-central1-a for region us-central1
  gcloud config set compute/region "$region"
  gcloud config set compute/zone "$zone"
  echo "GCP region set to: $region and compute zone set to: $zone"
}

# Function to display current gcloud configurations
  display_current_configurations() {
  echo "Current gcloud configurations:"
  echo "============================="
  gcloud config configurations list
  echo "============================="
  echo "Current gcloud config:"
  echo "============================="
  gcloud config list
  echo "============================="
  echo "Confirm GKE cluster:"
  echo "============================="
  gcloud container clusters list
  echo "============================="
}

# Main menu
show_menu() {
  echo "Select an option:"
  echo "1) Set an existing GCP project"
  echo "2) Set a GKE cluster"
  echo "3) Create new gcloud configuration for a GCP project and login"
  echo "4) Set GCP region and zone for a GCP project"
  echo "5) Exit"
}

# Loop to show menu and process user input
while true; do
  show_menu
  read -rp "Enter your choice: " choice

  case $choice in
    1)
      read -rp "Enter GCP project ID: " project_id
      activate_gcp_project "$project_id"
      ;;
    2)
      read -rp "Enter GKE cluster name: " cluster_name
      read -rp "Enter GKE cluster region: " cluster_region
      set_gke_cluster "$cluster_name" "$cluster_region"
      ;;
    3)
      read -rp "Enter GCP project ID: " project_id
      create_gcloud_config "$project_id"
      ;;
    4)
      read -rp "Enter GCP region: " region
      read -rp "Enter GCP zone: " zone
      set_gcloud_region "$region" "$zone"
      ;;
    5)
      echo "Exiting..."
      display_current_configurations
      exit 0
      ;;
  esac
done
