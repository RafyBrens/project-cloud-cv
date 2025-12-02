# GCP CV Website - Terraform Infrastructure
# Cloud Computing Final Project

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "firestore.googleapis.com",
    "storage.googleapis.com",
    "artifactregistry.googleapis.com"
  ])
  
  service            = each.value
  disable_on_destroy = false
}

# Cloud Storage bucket for resume PDF and images
resource "google_storage_bucket" "cv_assets" {
  name          = "${var.project_id}-cv-assets"
  location      = var.region
  force_destroy = true
  
  uniform_bucket_level_access = true
  
  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
  
  depends_on = [google_project_service.required_apis]
}

# Make bucket publicly readable
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.cv_assets.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Firestore Database (Native mode)
resource "google_firestore_database" "cv_database" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.firestore_location
  type        = "FIRESTORE_NATIVE"
  
  depends_on = [google_project_service.required_apis]
}

# Service Account for Cloud Run
resource "google_service_account" "cv_service_account" {
  account_id   = "cv-website-sa"
  display_name = "CV Website Service Account"
  description  = "Service account for CV website Cloud Run service"
}

# Grant Firestore access to service account
resource "google_project_iam_member" "firestore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.cv_service_account.email}"
}

# Grant Storage access to service account
resource "google_project_iam_member" "storage_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.cv_service_account.email}"
}

# Note: Cloud Run service will be deployed separately via gcloud
# This allows us to build and deploy from source without managing Docker images in Terraform

