#!/bin/bash

# GCP CV Website - One-Command Deployment Script
# Cloud Computing Final Project

set -e

echo "======================================"
echo "GCP CV Website Deployment"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${YELLOW}Error: gcloud CLI is not installed${NC}"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${YELLOW}Error: Terraform is not installed${NC}"
    echo "Please install it from: https://www.terraform.io/downloads"
    exit 1
fi

echo -e "${BLUE}Step 1: Authenticating with GCP...${NC}"
gcloud auth application-default login

echo ""
echo -e "${BLUE}Step 2: Setting GCP project...${NC}"
PROJECT_ID=$(grep 'project_id' terraform/terraform.tfvars | cut -d'"' -f2)
echo "Project ID: $PROJECT_ID"
gcloud config set project $PROJECT_ID

echo ""
echo -e "${BLUE}Step 3: Initializing Terraform...${NC}"
cd terraform
terraform init

echo ""
echo -e "${BLUE}Step 4: Planning infrastructure deployment...${NC}"
terraform plan

echo ""
echo -e "${YELLOW}Ready to deploy? This will create cloud resources.${NC}"
read -p "Continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}Step 5: Applying Terraform configuration...${NC}"
terraform apply -auto-approve

echo ""
echo -e "${BLUE}Step 6: Building and deploying application to Cloud Run...${NC}"
cd ../app

# Get region from terraform
REGION=$(grep 'region' ../terraform/terraform.tfvars | cut -d'"' -f2)

# Deploy to Cloud Run from source
gcloud run deploy cv-website \
    --source . \
    --region $REGION \
    --platform managed \
    --allow-unauthenticated \
    --service-account cv-website-sa@${PROJECT_ID}.iam.gserviceaccount.com

echo ""
echo -e "${GREEN}======================================"
echo "Deployment Complete!"
echo "======================================${NC}"
echo ""

# Get the service URL
cd ../terraform
SERVICE_URL=$(terraform output -raw service_url 2>/dev/null || echo "")

if [ -n "$SERVICE_URL" ]; then
    echo -e "${GREEN}Your CV website is live at:${NC}"
    echo -e "${BLUE}$SERVICE_URL${NC}"
    echo ""
fi

echo -e "${YELLOW}Next steps:${NC}"
echo "1. Edit app/data/cv_data.json with your actual CV information"
echo "2. Upload your CV PDF to Cloud Storage bucket"
echo "3. Update the downloadCV() function in app/static/script.js"
echo ""
echo -e "${GREEN}To view outputs:${NC} cd terraform && terraform output"
echo -e "${GREEN}To update CV:${NC} Edit cv_data.json and re-run this script"
echo -e "${GREEN}To destroy:${NC} cd terraform && terraform destroy"
echo ""

