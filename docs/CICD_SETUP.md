# CI/CD Pipeline Setup Guide

## Overview

This repository now includes a complete CI/CD pipeline configured for AWS Serverless deployment with the following features:

- 🚀 **Automated deployments** to staging and production
- 🔒 **Security scanning** with dependency checks
- ✅ **Quality gates** for build size and test coverage
- 📧 **Email notifications** for pipeline status
- 💰 **Cost optimization** within Free Tier limits
- 🔄 **Progressive retry logic** for reliability
- 📊 **CloudWatch monitoring** and alerts

## Quick Start

### Prerequisites

1. **AWS Account**: You need an AWS account with appropriate permissions
2. **GitHub Repository**: This pipeline is configured for GitHub Actions
3. **Email Account**: For notifications (Gmail recommended)

### Step 1: Configure GitHub Secrets

Go to your repository Settings > Secrets and variables > Actions, and add:

| Secret Name | Description | Example |
|------------|-------------|----------|
| `AWS_ACCESS_KEY_ID` | AWS IAM user access key | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM user secret key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_ACCOUNT_ID` | Your AWS account ID | `123456789012` |
| `EMAIL_USERNAME` | Gmail address for notifications | `your-email@gmail.com` |
| `EMAIL_PASSWORD` | Gmail app password (not regular password) | `abcd efgh ijkl mnop` |

#### Creating Gmail App Password:
1. Go to [Google Account Settings](https://myaccount.google.com/)
2. Security > 2-Step Verification (must be enabled)
3. App passwords > Select "Mail" > Generate
4. Use the generated 16-character password

### Step 2: Create IAM Role for Lambda

Run this AWS CLI command or use AWS Console:

```bash
aws iam create-role \
  --role-name lambda-execution-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "lambda.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy \
  --role-name lambda-execution-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
```

### Step 3: Deploy the Pipeline

The pipeline is now active and will:

1. **On push to `develop`/`staging`**: Deploy to staging environment
2. **On push to `main`**: Deploy to production environment
3. **On pull requests**: Run tests and security scans only

## Pipeline Architecture

```
┌─────────────────┐
│  GitHub Push    │
└────────┬────────┘
         ↓
┌─────────────────┐
│  Build & Test   │ ← Retry logic (3 attempts)
└────────┬────────┘
         ↓
┌─────────────────┐
│ Security Scan   │ ← SAST, dependency check
└────────┬────────┘
         ↓
┌─────────────────┐
│ Quality Gates   │ ← Build size, coverage
└────────┬────────┘
         ↓
    ┌────┴────┐
    ↓         ↓
┌──────┐  ┌──────┐
│Staging│  │ Prod │
└──────┘  └──────┘
    ↓         ↓
┌─────────────────┐
│  Notifications  │ ← Email alerts
└─────────────────┘
```

## Deployment Environments

### Staging Environment
- **Trigger**: Push to `develop` or `staging` branch
- **Frontend**: `http://webapp-demo-staging-{buildId}.s3-website-us-east-1.amazonaws.com`
- **API**: Lambda function URL (auto-generated)
- **Retention**: 7 days (auto-cleanup)

### Production Environment
- **Trigger**: Push to `main` branch
- **Frontend**: `http://webapp-demo-production.s3-website-us-east-1.amazonaws.com`
- **API**: Lambda function URL (auto-generated)
- **Retention**: Permanent

## Cost Breakdown

| Service | Free Tier | Your Usage | Monthly Cost |
|---------|-----------|------------|-------------|
| AWS Lambda | 1M requests, 400K GB-s | ~100K requests | **$0.00** |
| Amazon S3 | 5GB storage, 20K GET | <1GB storage | **$0.00** |
| CloudWatch | 5GB logs, 10 metrics | <1GB logs | **$0.00** |
| **Total** | - | - | **$0.00 - $5.00** |

## Monitoring & Alerts

### CloudWatch Dashboard
View metrics at: [CloudWatch Console](https://console.aws.amazon.com/cloudwatch/)
- Dashboard name: `webapp-demo-dashboard`
- Metrics: Lambda invocations, errors, duration, S3 storage

### Email Alerts
You'll receive emails for:
- Pipeline failures
- Lambda errors (>5 in 5 minutes)
- Budget alerts (>80% of $5 monthly)
- Weekly cost reports

## Manual Deployment

To deploy manually from AWS CloudShell:

```bash
# Clone the repository
git clone https://github.com/softengrahmed/webapp-demo.git
cd webapp-demo

# Build the application
yarn install
yarn nx run-many --target=build --all --prod

# Run deployment script
chmod +x scripts/deploy.sh
./scripts/deploy.sh staging  # or 'production'
```

## Maintenance Tasks

### Weekly Cleanup (Automated)
Runs every Monday at 2 AM UTC:
- Removes staging S3 buckets older than 7 days
- Deletes old Lambda versions
- Cleans CloudWatch logs

### Manual Cleanup
```bash
# Trigger cleanup workflow manually
gh workflow run cleanup-resources.yml
```

### Update Monitoring
```bash
# Trigger monitoring setup
gh workflow run setup-monitoring.yml
```

## Troubleshooting

### Common Issues

1. **Lambda deployment fails**
   - Check IAM role exists: `lambda-execution-role`
   - Verify AWS credentials in GitHub Secrets

2. **Email notifications not working**
   - Ensure Gmail app password (not regular password)
   - Check 2-factor authentication is enabled

3. **Build size exceeds limit**
   - Review dependencies in package.json
   - Enable production optimizations

4. **S3 bucket already exists**
   - For production, bucket names must be globally unique
   - Modify bucket name in workflow files

## Security Best Practices

1. **Rotate AWS keys** every 90 days
2. **Use least privilege** IAM policies
3. **Enable MFA** on AWS account
4. **Review security scan** results regularly
5. **Keep dependencies** updated

## Support

For issues or questions:
1. Check the [GitHub Actions logs](https://github.com/softengrahmed/webapp-demo/actions)
2. Review CloudWatch logs in AWS Console
3. Contact: ilyasirfanahmed@gmail.com

## License

MIT License - See LICENSE file for details

---

*Generated by Intelligent CI/CD Pipeline Generator v3.0*
*Last updated: August 14, 2025*