# Outputs for GCP CV Website

output "service_url" {
  description = "URL of the deployed CV website (will be set after gcloud deploy)"
  value       = "Run 'gcloud run services describe cv-website --region=${var.region} --format=value(status.url)' to get URL after deployment"
}

output "storage_bucket_name" {
  description = "Name of the Cloud Storage bucket for assets"
  value       = google_storage_bucket.cv_assets.name
}

output "storage_bucket_url" {
  description = "Public URL for storage bucket"
  value       = "https://storage.googleapis.com/${google_storage_bucket.cv_assets.name}"
}

output "firestore_database" {
  description = "Firestore database name"
  value       = google_firestore_database.cv_database.name
}

output "service_account_email" {
  description = "Service account email for the CV website"
  value       = google_service_account.cv_service_account.email
}

output "deployment_info" {
  description = "Deployment information"
  value = {
    project      = var.project_id
    region       = var.region
    service_name = var.service_name
  }
}

