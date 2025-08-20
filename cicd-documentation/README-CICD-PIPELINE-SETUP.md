# CI/CD Pipeline Setup Guide

## 📋 Overview

This repository contains a complete CI/CD pipeline implementation using the "Pipeline as Specs" 3-tier system.

- **Version**: v1-2025-08-10
- **Repository**: github.com/softengrahmed/webapp-demo
- **Platform**: AWS Serverless (Lambda + API Gateway + Aurora)
- **Tier**: Minimal ($5-15/month)
- **Environments**: dev → prod

## 🚀 Quick Start

### 1. Prerequisites

- AWS Account with appropriate permissions
- GitHub repository access
- Basic understanding of GitHub Actions and AWS

### 2. Setup GitHub Secrets

Add the following secrets to your GitHub repository:

```bash
AWS_ACCESS_KEY_ID        # Your AWS access key
AWS_SECRET_ACCESS_KEY    # Your AWS secret key
AWS_ACCOUNT_ID          # Your AWS account ID (optional)
```

### 3. Configure Environments

The pipeline supports two environments:
- **dev**: Automatically deployed from `dev` branch
- **prod**: Automatically deployed from `main` branch

### 4. Activate the Pipeline

1. Merge this PR to your main branch
2. The pipeline will automatically trigger on:
   - Push to `main` or `dev` branches
   - Pull requests to `main`
   - Manual workflow dispatch

## 📦 Pipeline Features

### Enabled Features
- ✅ **Security Scanning**: SAST analysis and dependency checks
- ✅ **Quality Gates**: 80% code coverage requirement
- ✅ **Retry Logic**: 3 attempts with exponential backoff
- ✅ **Cost Optimization**: Minimal resource allocation

### Pipeline Stages
1. **Build**: Detect language and create artifacts
2. **Security Scan**: Run CodeQL and dependency checks
3. **Quality Gates**: Verify code coverage and quality
4. **Deploy**: Deploy to AWS Serverless infrastructure
5. **Verify**: Run health checks and smoke tests
6. **Report**: Generate execution reports
7. **Cleanup**: Clean temporary resources

## 💰 Cost Breakdown

| Service | Configuration | Monthly Cost |
|---------|--------------|-------------|
| Lambda | 256MB, 100K requests | $4-6 |
| Aurora Serverless | 0.5-1 ACU | $3-5 |
| API Gateway | 100K calls | $1-2 |
| CloudWatch | Basic monitoring | $1-2 |
| **Total** | | **$10-15** |

## 🏗️ Architecture

```
webapp-demo/
├── .github/workflows/       # GitHub Actions workflows
├── cicd-specifications/     # Pipeline specifications
├── cicd-pipeline-configs/   # Configuration files
├── cicd-infrastructure/     # AWS templates
└── cicd-documentation/      # Documentation
```

## 🔧 Customization

### Adjust Resource Limits

Edit environment variables in `.github/workflows/cicd-main-pipeline-2025-08-10.yaml`:

```yaml
env:
  LAMBDA_MEMORY_SIZE: 256  # Increase for better performance
  AURORA_MIN_ACU: 0.5      # Increase for higher baseline
  AURORA_MAX_ACU: 1.0      # Increase for more scaling
```

### Modify Quality Gates

Edit `cicd-pipeline-configs/quality-gates-config.yaml`:

```yaml
quality_gates:
  code_coverage:
    threshold: 80  # Adjust coverage requirement
```

## 📊 Monitoring

- **GitHub Actions**: View pipeline runs in Actions tab
- **AWS CloudWatch**: Monitor Lambda and Aurora metrics
- **Cost Explorer**: Track AWS spending

## 🆘 Troubleshooting

### Common Issues

1. **AWS Credentials Error**
   - Verify GitHub secrets are correctly set
   - Check IAM permissions

2. **Deployment Failures**
   - Check CloudFormation stack events
   - Review Lambda function logs

3. **Quality Gate Failures**
   - Increase test coverage
   - Fix critical security issues

## 📚 Additional Resources

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Aurora Serverless v2 Guide](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.html)

## 📝 License

This pipeline configuration is provided as-is for the webapp-demo project.

---

**Generated**: 2025-08-10 14:30:45  
**Pipeline Version**: v1-2025-08-10  
**Support**: Create an issue in the repository for help