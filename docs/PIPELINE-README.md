# Pipeline Implementation Guide

## Overview

This document provides comprehensive guidance for the CI/CD pipeline implementation for the webapp-demo repository.

## Quick Start

### Prerequisites

1. **AWS Account Setup**
   - Create an AWS account if you don't have one
   - Set up IAM user with programmatic access
   - Required permissions: Lambda, API Gateway, RDS, S3, CloudWatch, IAM

2. **GitHub Secrets Configuration**
   ```
   AWS_ACCESS_KEY_ID=your_access_key
   AWS_SECRET_ACCESS_KEY=your_secret_key
   SONAR_TOKEN=your_sonar_token (optional)
   SNYK_TOKEN=your_snyk_token (optional)
   ```

3. **Branch Structure**
   - `dev` - Development environment (auto-deploy)
   - `main` - Production environment (manual approval)

## Pipeline Architecture

### Stages

1. **Build Stage** (10 minutes)
   - Checkout code
   - Install dependencies
   - Run linting
   - Execute tests with coverage
   - Build production artifacts
   - Package Lambda functions

2. **Security Stage** (5 minutes)
   - NPM audit for known vulnerabilities
   - Snyk security scanning
   - SonarCloud SAST analysis
   - Container vulnerability scanning

3. **Deploy Stage** (15 minutes)
   - Deploy infrastructure via SAM/CloudFormation
   - Update Lambda function code
   - Configure API Gateway
   - Set up blue-green deployment (production only)

4. **Verify Stage** (5 minutes)
   - Health check validation
   - Smoke test execution
   - Performance monitoring
   - Rollback decision

5. **Report Stage** (3 minutes)
   - Generate deployment reports
   - Send notifications
   - Update metrics dashboard

6. **Cleanup Stage** (2 minutes)
   - Remove temporary resources
   - Archive old artifacts

## AWS Resources

### Lambda Configuration
```yaml
Runtime: Node.js 18.x
Memory: 256 MB
Timeout: 30 seconds
Architecture: x86_64
Reserved Concurrency: 5
```

### Aurora Serverless v2
```yaml
Engine: MySQL 5.7
Minimum ACU: 0.5
Maximum ACU: 1.0
Auto-pause: After 5 minutes
Backup Retention: 7 days
```

### API Gateway
```yaml
Type: REST API
Throttle Burst: 100 requests
Throttle Rate: 50 requests/second
CORS: Enabled
Stages: dev, prod
```

## Blue-Green Deployment

Production deployments use blue-green strategy:

1. Deploy new version to "green" environment
2. Run validation tests (5 minutes)
3. Shift 10% traffic to new version
4. Monitor error rates and latency
5. Gradually increase traffic to 100%
6. Automatic rollback on failures

## Quality Gates

### Required Checks
- ✅ Code coverage ≥ 80%
- ✅ No critical security issues
- ✅ All tests passing
- ✅ TypeScript compilation successful
- ✅ ESLint no errors

### Security Scanning
- NPM audit (critical vulnerabilities block deployment)
- Snyk vulnerability scanning
- SonarCloud code quality analysis
- AWS ECR container scanning

## Cost Optimization

### Implemented Strategies
1. **Auto-scaling**: Lambda scales automatically
2. **Aurora Auto-pause**: Database pauses after 5 minutes idle
3. **S3 Lifecycle**: Old artifacts deleted after 30 days
4. **Reserved Capacity**: None (pay-per-use model)
5. **Budget Alerts**: Notification at $10 threshold

### Estimated Monthly Costs
- Lambda Compute: $4-5
- Aurora Database: $3-4  
- API Gateway: $1.50
- S3 Storage: $1
- CloudWatch: $0.50
- **Total: $10-12/month**

## Monitoring & Observability

### CloudWatch Metrics
- Lambda invocations and errors
- API Gateway 4xx/5xx errors
- Database connections and query performance
- Cold start duration
- Memory utilization

### Alarms
- High error rate (>1%)
- Database connection failures
- Lambda throttling
- Budget threshold exceeded

### Logging
- Structured JSON logging
- Centralized in CloudWatch Logs
- 7-day retention (dev)
- 30-day retention (prod)

## Rollback Procedures

### Automatic Rollback Triggers
- Health check failures (3 consecutive)
- Error rate > 5%
- Response time > 3 seconds
- Memory usage > 90%

### Manual Rollback
```bash
# Rollback Lambda to previous version
aws lambda update-alias \
  --function-name webapp-demo-api-prod \
  --name live \
  --function-version $PREVIOUS_VERSION
```

## Troubleshooting

### Common Issues

1. **Build Failures**
   - Check Node.js version (requires 18.x)
   - Verify yarn.lock is committed
   - Clear yarn cache: `yarn cache clean`

2. **Deployment Failures**
   - Verify AWS credentials
   - Check IAM permissions
   - Review CloudFormation events

3. **Test Failures**
   - Run tests locally: `yarn test`
   - Check coverage: `yarn test --coverage`
   - Review test logs in GitHub Actions

## Security Best Practices

1. **Secrets Management**
   - Use AWS Secrets Manager
   - Rotate credentials every 90 days
   - Never commit secrets to repository

2. **IAM Policies**
   - Least privilege principle
   - Separate roles for dev/prod
   - Regular permission audits

3. **Network Security**
   - VPC isolation for database
   - Security groups with minimal ports
   - API Gateway throttling

## Support

For issues or questions:
1. Check this documentation
2. Review pipeline logs in GitHub Actions
3. Check AWS CloudWatch logs
4. Create an issue in the repository

---

*Last Updated: 2025-08-10*
*Pipeline Version: v1-2025-08-10-14-30-45*
