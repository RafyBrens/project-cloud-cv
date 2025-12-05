# Cloud CV Platform - GCP Final Project

A production-ready, serverless online CV website built with Google Cloud Platform, demonstrating modern cloud-native architecture and Infrastructure as Code principles.

## Overview

This project is a fully automated, scalable CV/resume website deployed on Google Cloud Platform. It features a modern web interface, visitor analytics, contact form, and automated infrastructure provisioning - all deployable with a single command.

```
                                    ┌─────────────────┐
                                    │   User Browser  │
                                    └────────┬────────┘
                                             │ HTTPS
                                    ┌────────▼────────┐
                                    │  Cloud Run      │
                                    │  (Auto-scaling) │
                                    │  Flask App      │
                                    └────┬────┬───────┘
                                         │    │
                          ┌──────────────┘    └──────────────┐
                          │                                   │
                   ┌──────▼───────┐                  ┌───────▼────────┐
                   │  Firestore   │                  │ Cloud Storage  │
                   │  (NoSQL DB)  │                  │ (Assets/PDFs)  │
                   │  - Analytics │                  │ - Resume PDF   │
                   │  - Contacts  │                  │ - Images       │
                   └──────────────┘                  └────────────────┘
```

## Features

- **Modern Responsive Design**: Professional CV layout that works on all devices
- **Serverless Architecture**: Auto-scaling Cloud Run container (0 to N instances)
- **Visitor Analytics**: Track page views and visitor data in Firestore
- **Contact Form**: Allow visitors to send messages (stored in Firestore)
- **Cloud Storage Integration**: Host resume PDFs and assets
- **Infrastructure as Code**: Complete Terraform automation
- **One-Command Deployment**: Deploy entire stack with `./deploy.sh`
- **Cost Optimized**: Uses GCP free tier (~$0-2/month)

## Technologies Used

### Cloud Infrastructure
- **Google Cloud Run**: Serverless container platform
- **Firestore**: NoSQL database for analytics and contacts
- **Cloud Storage**: Object storage for resume PDFs
- **Cloud Build**: Automated container builds
- **Terraform**: Infrastructure as Code

### Application Stack
- **Backend**: Python Flask REST API
- **Frontend**: HTML5, CSS3, JavaScript (Vanilla)
- **Container**: Docker
- **Server**: Gunicorn WSGI

## Cloud Computing Concepts Demonstrated

1. **Serverless Computing**: Cloud Run provides auto-scaling from 0 to 10 instances based on traffic
2. **NoSQL Databases**: Firestore for flexible schema and real-time data
3. **Object Storage**: Cloud Storage for static assets with CDN capabilities
4. **Infrastructure as Code**: Terraform for reproducible deployments
5. **Containerization**: Docker for portable, consistent deployments
6. **Managed Services**: Fully managed infrastructure (no VM maintenance)
7. **IAM & Security**: Service accounts with least privilege access
8. **Auto-scaling**: Automatic resource allocation based on demand
9. **RESTful APIs**: Clean API design for frontend-backend communication
10. **Cost Optimization**: Pay-per-use model with generous free tiers

## Prerequisites

- Google Cloud Platform account
- `gcloud` CLI installed and configured
- `terraform` installed (v1.0+)
- GCP project created (project ID: `projectrb-1`)

## Quick Start - One Command Deployment

```bash
cd /Users/rafaelbrens/code/classes/fall25/cloud/project
chmod +x deploy.sh
./deploy.sh
```

That's it! The script will:
1. Authenticate with GCP
2. Initialize Terraform
3. Provision all cloud infrastructure
4. Build and deploy the Docker container
5. Output your live website URL

## Detailed Deployment Steps

If you prefer manual deployment:

### 1. Authenticate with GCP

```bash
gcloud auth application-default login
gcloud config set project projectrb-1
```

### 2. Deploy Infrastructure with Terraform

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This creates:
- Cloud Storage bucket for assets
- Firestore database
- Service account with required permissions
- Cloud Run service configuration

### 3. Deploy Application to Cloud Run

```bash
cd ../app
gcloud run deploy cv-website \
    --source . \
    --region us-east4 \
    --platform managed \
    --allow-unauthenticated
```

### 4. Get Your Website URL

```bash
cd ../terraform
terraform output service_url
```

## Project Structure

```
project/
├── terraform/                  # Infrastructure as Code
│   ├── main.tf                # Main Terraform configuration
│   ├── variables.tf           # Input variables
│   ├── outputs.tf             # Output values
│   └── terraform.tfvars       # Configuration values
├── app/                       # Application code
│   ├── Dockerfile             # Container definition
│   ├── requirements.txt       # Python dependencies
│   ├── main.py                # Flask backend API
│   ├── static/                # Frontend files
│   │   ├── index.html         # CV website
│   │   ├── styles.css         # Styling
│   │   └── script.js          # JavaScript
│   └── data/                  # CV content
│       └── cv_data.json       # Your CV data
├── deploy.sh                  # One-command deployment
├── .gcloudignore              # Files to ignore during deployment
└── README.md                  # This file
```

## Customization

### Update Your CV Information

Edit `app/data/cv_data.json` with your actual information:

```json
{
  "name": "Your Name",
  "title": "Your Title",
  "email": "your.email@example.com",
  "summary": "Your professional summary...",
  "experience": [...],
  "education": [...],
  "skills": [...],
  "projects": [...]
}
```

Then redeploy:

```bash
./deploy.sh
```

### Add Your Resume PDF

1. Upload your resume PDF to Cloud Storage:

```bash
BUCKET=$(cd terraform && terraform output -raw storage_bucket_name)
gsutil cp your-resume.pdf gs://$BUCKET/cv.pdf
```

2. Update the download function in `app/static/script.js`:

```javascript
function downloadCV() {
    const pdfUrl = 'https://storage.googleapis.com/YOUR-BUCKET/cv.pdf';
    window.open(pdfUrl, '_blank');
}
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Serve CV website |
| `/api/cv-data` | GET | Get CV data JSON |
| `/api/contact` | POST | Submit contact form |
| `/api/analytics` | POST | Track page view |
| `/api/stats` | GET | Get visitor statistics |
| `/health` | GET | Health check |

## Cost Analysis

### Free Tier Coverage
- **Cloud Run**: 2M requests/month, 360K GB-seconds/month
- **Firestore**: 1GB storage, 50K reads/day, 20K writes/day
- **Cloud Storage**: 5GB storage, 5K Class A operations/month

### Estimated Monthly Cost
- **Cloud Run**: $0 (well within free tier)
- **Firestore**: $0 (well within free tier)
- **Cloud Storage**: ~$0.02 (minimal usage)
- **Total**: ~$0-2/month

For a personal CV site with moderate traffic (100-500 views/month), this stays in free tier.

## Monitoring & Analytics

### View Visitor Statistics

Access the stats API:

```bash
curl https://YOUR-SERVICE-URL/api/stats
```

### View Firestore Data

```bash
# View contacts
gcloud firestore documents list contacts --project=projectrb-1

# View analytics
gcloud firestore documents list analytics --project=projectrb-1
```

### Cloud Run Metrics

Visit: https://console.cloud.google.com/run/detail/us-east4/cv-website/metrics

## Maintenance

### View Logs

```bash
gcloud run logs read cv-website --region=us-east4 --limit=50
```

### Update Application

After making changes to code:

```bash
cd app
gcloud run deploy cv-website \
    --source . \
    --region us-east4 \
    --platform managed
```

### Destroy Infrastructure

```bash
cd terraform
terraform destroy
```

## Security Features

- **HTTPS Only**: Cloud Run provides automatic SSL/TLS
- **IAM Service Account**: Least privilege access to GCP resources
- **Public Access**: Controlled via Cloud Run IAM policies
- **No Hardcoded Secrets**: Environment variables for configuration
- **CORS Enabled**: Controlled cross-origin access for storage

## Performance

- **Cold Start**: ~2-3 seconds (Python Flask on Cloud Run)
- **Warm Response**: ~50-200ms
- **Auto-scaling**: 0 to 10 instances based on load
- **Global CDN**: Cloud Storage with CDN capabilities

## Future Enhancements

- [ ] Custom domain with Cloud DNS
- [ ] A/B testing for different CV layouts
- [ ] Multi-language support
- [ ] Blog section with CMS
- [ ] Admin dashboard for analytics
- [ ] Email notifications for contact form (SendGrid integration)
- [ ] Resume PDF generation from JSON data
- [ ] Dark mode toggle
- [ ] Multi-region deployment for global performance

## Troubleshooting

### Deployment fails with "API not enabled"

```bash
gcloud services enable run.googleapis.com cloudbuild.googleapis.com firestore.googleapis.com
```

### "Permission denied" errors

Ensure your service account has required roles:

```bash
gcloud projects add-iam-policy-binding projectrb-1 \
    --member=serviceAccount:cv-website-sa@projectrb-1.iam.gserviceaccount.com \
    --role=roles/datastore.user
```

### Website not loading

Check Cloud Run logs:

```bash
gcloud run logs read cv-website --region=us-east4 --limit=100
```

## Learning Outcomes

This project demonstrates:
- Building production-ready cloud applications
- Serverless architecture patterns
- Infrastructure automation with Terraform
- Modern web development practices
- Cloud cost optimization
- Security best practices
- DevOps workflows

## Contributing

This is a final project for Cloud Computing course. Feel free to use it as a template for your own CV website!

## License

Do not copy!

## Contact

For questions about this project, use the contact form on the deployed website or reach out via the email in the CV.

---

**Built with Google Cloud Platform | Terraform | Python Flask | Docker**

*Cloud Computing Final Project - December 2025*

