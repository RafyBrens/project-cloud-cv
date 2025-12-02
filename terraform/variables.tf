# Variables for GCP CV Website

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region for Cloud Run deployment"
  type        = string
  default     = "us-east4"
}

variable "firestore_location" {
  description = "Firestore database location (must be region or multi-region)"
  type        = string
  default     = "nam5"  # North America multi-region
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
  default     = "cv-website"
}

