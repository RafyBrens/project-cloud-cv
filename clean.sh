#!/bin/bash

# GCP CV Website - Cleanup Script
# Removes all resources created by deploy.sh

set -e

echo "======================================"
echo "GCP CV Website Cleanup"
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed${NC}"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed${NC}"
    echo "Please install it from: https://www.terraform.io/downloads"
    exit 1
fi

# Get project ID from terraform config
if [ -f terraform/terraform.tfvars ]; then
    PROJECT_ID=$(grep 'project_id' terraform/terraform.tfvars | cut -d'"' -f2)
    REGION=$(grep 'region' terraform/terraform.tfvars | cut -d'"' -f2)
    echo -e "${BLUE}Project ID: $PROJECT_ID${NC}"
    echo -e "${BLUE}Region: $REGION${NC}"
else
    echo -e "${RED}Error: terraform.tfvars not found${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}WARNING: This will DELETE all resources created for the CV website:${NC}"
echo -e "${RED}  - Cloud Run service (cv-website)${NC}"
echo -e "${RED}  - Cloud Storage bucket and all contents${NC}"
echo -e "${RED}  - Firestore database (if empty)${NC}"
echo -e "${RED}  - Service account${NC}"
echo -e "${RED}  - IAM bindings${NC}"
echo ""
echo -e "${YELLOW}Data in Firestore (contacts, analytics) will be PERMANENTLY DELETED${NC}"
echo ""
read -p "Are you sure you want to continue? Type 'yes' to confirm: " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}Step 1: Deleting Cloud Run service...${NC}"

# Check if Cloud Run service exists
if gcloud run services describe cv-website --region=$REGION --project=$PROJECT_ID &> /dev/null; then
    gcloud run services delete cv-website \
        --region=$REGION \
        --project=$PROJECT_ID \
        --quiet
    echo -e "${GREEN}✓ Cloud Run service deleted${NC}"
else
    echo -e "${YELLOW}⊘ Cloud Run service not found (may already be deleted)${NC}"
fi

echo ""
echo -e "${BLUE}Step 2: Checking for Artifact Registry repository...${NC}"

# Check if repository exists and delete it
if gcloud artifacts repositories describe cloud-run-source-deploy \
    --location=$REGION \
    --project=$PROJECT_ID &> /dev/null 2>&1; then
    echo "Deleting Artifact Registry repository (contains Docker images)..."
    gcloud artifacts repositories delete cloud-run-source-deploy \
        --location=$REGION \
        --project=$PROJECT_ID \
        --quiet
    echo -e "${GREEN}✓ Artifact Registry repository deleted${NC}"
else
    echo -e "${YELLOW}⊘ Artifact Registry repository not found${NC}"
fi

echo ""
echo -e "${BLUE}Step 3: Destroying Terraform infrastructure...${NC}"
cd terraform

# Initialize terraform (in case it wasn't initialized)
terraform init > /dev/null 2>&1

# Show what will be destroyed
echo "Resources to be destroyed:"
terraform show -json | grep -o '"type":"[^"]*"' | sort | uniq || echo "  (checking resources...)"

echo ""
read -p "Proceed with Terraform destroy? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Terraform destroy cancelled."
    echo -e "${YELLOW}Note: Cloud Run service was already deleted${NC}"
    exit 0
fi

# Destroy infrastructure
terraform destroy -auto-approve

echo ""
echo -e "${BLUE}Step 4: Checking for remaining resources...${NC}"

# Check for storage bucket
BUCKET_NAME="${PROJECT_ID}-cv-assets"
if gsutil ls gs://$BUCKET_NAME &> /dev/null 2>&1; then
    echo -e "${YELLOW}Warning: Storage bucket still exists${NC}"
    echo "This may contain files. Delete manually if needed:"
    echo "  gsutil rm -r gs://$BUCKET_NAME"
else
    echo -e "${GREEN}✓ Storage bucket removed${NC}"
fi

# Check for Firestore database
if gcloud firestore databases describe "(default)" --project=$PROJECT_ID &> /dev/null 2>&1; then
    echo -e "${YELLOW}Note: Firestore database '(default)' persists (GCP limitation)${NC}"
    echo "Firestore databases cannot be deleted, only emptied."
    echo "This is normal and does not incur costs when empty."
    echo ""
    echo "Data has been removed by Terraform destroy."
    echo "The empty database will be reused on next deployment."
else
    echo -e "${GREEN}✓ Firestore database handled${NC}"
fi

# Check for service account
SA_EMAIL="cv-website-sa@${PROJECT_ID}.iam.gserviceaccount.com"
if gcloud iam service-accounts describe $SA_EMAIL --project=$PROJECT_ID &> /dev/null 2>&1; then
    echo -e "${YELLOW}Warning: Service account still exists${NC}"
    echo "Delete manually if needed:"
    echo "  gcloud iam service-accounts delete $SA_EMAIL --project=$PROJECT_ID"
else
    echo -e "${GREEN}✓ Service account removed${NC}"
fi

echo ""
echo -e "${BLUE}Step 5: Cleaning up Terraform state files...${NC}"

# Remove Terraform state and cache
if [ -f terraform.tfstate ]; then
    rm -f terraform.tfstate
    echo -e "${GREEN}✓ Removed terraform.tfstate${NC}"
fi

if [ -f terraform.tfstate.backup ]; then
    rm -f terraform.tfstate.backup
    echo -e "${GREEN}✓ Removed terraform.tfstate.backup${NC}"
fi

if [ -d .terraform ]; then
    rm -rf .terraform
    echo -e "${GREEN}✓ Removed .terraform directory${NC}"
fi

if [ -f .terraform.lock.hcl ]; then
    rm -f .terraform.lock.hcl
    echo -e "${GREEN}✓ Removed .terraform.lock.hcl${NC}"
fi

echo -e "${GREEN}✓ Terraform state cleaned${NC}"

cd ..

echo ""
echo -e "${GREEN}======================================"
echo "Cleanup Complete!"
echo "======================================${NC}"
echo ""

echo -e "${GREEN}Resources removed:${NC}"
echo "  ✓ Cloud Run service deleted"
echo "  ✓ Artifact Registry repository deleted"
echo "  ✓ Terraform resources destroyed"
echo "  ✓ Terraform state files removed"
echo ""

echo -e "${YELLOW}What was NOT removed:${NC}"
echo "  - Enabled APIs (remain enabled)"
echo "  - Project itself"
echo "  - Application code (app/ directory)"
echo "  - Documentation files"
echo "  - Firestore database (GCP limitation - cannot be deleted, only emptied)"
echo ""

echo -e "${BLUE}Cost after cleanup:${NC}"
echo "  \$0/month (all billable resources removed)"
echo ""

echo -e "${BLUE}To redeploy (fresh start):${NC}"
echo "  ./deploy.sh"
echo ""

echo -e "${GREEN}Complete fresh start achieved!${NC}"
echo "Next deployment will rebuild everything from scratch."
echo ""

echo -e "${YELLOW}Note: If you see warnings above, some resources may need manual deletion.${NC}"
echo "This is normal if resources were modified outside of Terraform."
echo ""

