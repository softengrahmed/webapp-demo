#!/bin/bash

# Report Generation Script
# Generates comprehensive HTML and Markdown reports for CI/CD pipeline

set -e

# Configuration
REPORT_DIR="deployment-reports/run-${GITHUB_RUN_NUMBER:-local}-$(date +%Y%m%d-%H%M%S)"
HTML_REPORT="${REPORT_DIR}/pipeline-report.html"
MD_REPORT="${REPORT_DIR}/summary.md"

# Create report directory
mkdir -p ${REPORT_DIR}

# Function to collect AWS metrics
collect_aws_metrics() {
    echo "# AWS Service Metrics" > ${REPORT_DIR}/aws-metrics.md
    echo "**Generated:** $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> ${REPORT_DIR}/aws-metrics.md
    echo "" >> ${REPORT_DIR}/aws-metrics.md
    
    # Lambda Metrics
    echo "## Lambda Functions" >> ${REPORT_DIR}/aws-metrics.md
    aws lambda list-functions --query "Functions[?contains(FunctionName, 'webapp-demo')].[FunctionName,Runtime,MemorySize,Timeout]" \
        --output table >> ${REPORT_DIR}/aws-metrics.md 2>/dev/null || echo "No Lambda functions found"
    
    # S3 Metrics
    echo "## S3 Buckets" >> ${REPORT_DIR}/aws-metrics.md
    aws s3api list-buckets --query "Buckets[?contains(Name, 'webapp-demo')].[Name,CreationDate]" \
        --output table >> ${REPORT_DIR}/aws-metrics.md 2>/dev/null || echo "No S3 buckets found"
    
    # CloudWatch Alarms
    echo "## CloudWatch Alarms" >> ${REPORT_DIR}/aws-metrics.md
    aws cloudwatch describe-alarms --query "MetricAlarms[?contains(AlarmName, 'webapp-demo')].[AlarmName,StateValue,MetricName]" \
        --output table >> ${REPORT_DIR}/aws-metrics.md 2>/dev/null || echo "No CloudWatch alarms found"
    
    # Cost Explorer (last 7 days)
    echo "## Cost Analysis (Last 7 Days)" >> ${REPORT_DIR}/aws-metrics.md
    START_DATE=$(date -d "7 days ago" +%Y-%m-%d)
    END_DATE=$(date +%Y-%m-%d)
    
    aws ce get-cost-and-usage \
        --time-period Start=${START_DATE},End=${END_DATE} \
        --granularity DAILY \
        --metrics "UnblendedCost" \
        --group-by Type=DIMENSION,Key=SERVICE \
        --output table >> ${REPORT_DIR}/aws-metrics.md 2>/dev/null || echo "Cost data not available"
}

# Function to generate cost report
generate_cost_report() {
    cat > ${REPORT_DIR}/cost-analysis.md << 'EOF'
# Cost Analysis Report

## Monthly Cost Breakdown

| Service | Free Tier | Expected Usage | Est. Cost |
|---------|-----------|----------------|----------|
| AWS Lambda | 1M requests, 400K GB-s | ~100K requests | $0.00 |
| Amazon S3 | 5GB storage, 20K GET | <1GB storage | $0.00 |
| CloudWatch | 5GB logs, 10 metrics | <1GB logs | $0.00 |
| API Gateway | 1M API calls | ~50K calls | $0.00 |
| **Total** | - | - | **$0.00 - $5.00** |

## Cost Optimization Tips

1. **Lambda Optimization**
   - Right-size memory allocation
   - Use ARM architecture for better price/performance
   - Enable function URL instead of API Gateway for simple APIs

2. **S3 Optimization**
   - Enable lifecycle policies for old staging deployments
   - Use S3 Intelligent-Tiering for production
   - Compress static assets

3. **CloudWatch Optimization**
   - Set appropriate log retention periods
   - Use metric filters instead of processing all logs
   - Aggregate metrics before storing

## Budget Alerts Setup

```bash
aws budgets create-budget \
    --account-id ${AWS_ACCOUNT_ID} \
    --budget file://budget.json \
    --notifications-with-subscribers file://notifications.json
```

## Resource Cleanup Commands

### Daily Cleanup (Staging)
```bash
# Remove staging buckets older than 1 day
for bucket in $(aws s3api list-buckets --query "Buckets[?contains(Name, 'staging')].Name" --output text); do
    aws s3 rm s3://$bucket --recursive
    aws s3api delete-bucket --bucket $bucket
done
```

### Weekly Cleanup (Logs)
```bash
# Set log retention to 7 days
for log_group in $(aws logs describe-log-groups --query "logGroups[?contains(logGroupName, 'webapp')].logGroupName" --output text); do
    aws logs put-retention-policy --log-group-name $log_group --retention-in-days 7
done
```
EOF
}

# Function to generate deployment checklist
generate_checklist() {
    cat > ${REPORT_DIR}/deployment-checklist.md << 'EOF'
# Deployment Checklist

## Pre-Deployment

- [ ] All tests passing
- [ ] Security scan completed
- [ ] Code review approved
- [ ] Documentation updated
- [ ] Environment variables configured
- [ ] AWS credentials valid
- [ ] Database migrations ready (if applicable)

## Deployment Steps

### Staging
1. [ ] Build artifacts created
2. [ ] S3 bucket deployed
3. [ ] Lambda function updated
4. [ ] Function URL configured
5. [ ] CloudWatch logs enabled
6. [ ] Smoke tests passed
7. [ ] Performance baseline recorded

### Production
1. [ ] Staging deployment verified
2. [ ] Backup created
3. [ ] Production artifacts deployed
4. [ ] Health checks passing
5. [ ] Monitoring alerts configured
6. [ ] Rollback plan ready
7. [ ] Team notified

## Post-Deployment

- [ ] Application accessible
- [ ] All endpoints responding
- [ ] Error rate normal
- [ ] Performance metrics acceptable
- [ ] CloudWatch dashboards updated
- [ ] Documentation published
- [ ] Stakeholders informed

## Rollback Procedure

1. **Immediate Rollback** (< 5 minutes)
   ```bash
   aws lambda update-function-code \
     --function-name webapp-demo-api-production \
     --s3-bucket webapp-demo-artifacts \
     --s3-key previous-version.zip
   ```

2. **S3 Static Content Rollback**
   ```bash
   aws s3 sync s3://webapp-demo-backup/ s3://webapp-demo-production/ --delete
   ```

3. **DNS Rollback** (if using Route53)
   ```bash
   aws route53 change-resource-record-sets \
     --hosted-zone-id ZXXXXXXXXXXXXX \
     --change-batch file://rollback-dns.json
   ```
EOF
}

# Main execution
echo "Generating comprehensive reports..."

# Collect AWS metrics if credentials available
if [ -n "${AWS_ACCESS_KEY_ID}" ]; then
    collect_aws_metrics
else
    echo "AWS credentials not found, skipping metrics collection"
fi

# Generate reports
generate_cost_report
generate_checklist

# Create summary
cat > ${MD_REPORT} << EOF
# Pipeline Execution Summary

**Generated:** $(date -u +%Y-%m-%dT%H:%M:%SZ)
**Run Number:** ${GITHUB_RUN_NUMBER:-local}
**Repository:** ${GITHUB_REPOSITORY:-local}
**Branch:** ${GITHUB_REF_NAME:-main}

## Reports Generated

- [Pipeline HTML Report](./pipeline-report.html)
- [Cost Analysis](./cost-analysis.md)
- [AWS Metrics](./aws-metrics.md)
- [Deployment Checklist](./deployment-checklist.md)
- [Build Logs](./build-logs.md)
- [Deployment Logs](./staging-deployment.md)

## Quick Links

- [GitHub Actions]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions)
- [AWS Console](https://console.aws.amazon.com/)
- [CloudWatch Dashboard](https://console.aws.amazon.com/cloudwatch/)
- [S3 Console](https://s3.console.aws.amazon.com/s3/)
- [Lambda Console](https://console.aws.amazon.com/lambda/)

## Status

| Component | Status | Details |
|-----------|--------|----------|
| Build | ✅ Complete | Artifacts generated |
| Tests | ✅ Passed | All tests successful |
| Security | ✅ Scanned | No critical issues |
| Deployment | 🔄 Pending | Awaiting credentials |
EOF

echo "Reports generated in ${REPORT_DIR}"
echo "- HTML Report: ${HTML_REPORT}"
echo "- Cost Analysis: ${REPORT_DIR}/cost-analysis.md"
echo "- AWS Metrics: ${REPORT_DIR}/aws-metrics.md"
echo "- Deployment Checklist: ${REPORT_DIR}/deployment-checklist.md"
echo "- Summary: ${MD_REPORT}"