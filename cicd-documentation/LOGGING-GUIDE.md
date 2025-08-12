# CI/CD Pipeline Logging Guide

## Overview

This guide explains the comprehensive logging system implemented in the CI/CD pipeline for the webapp-demo repository.

## Logging Architecture

### Structure

The logging system captures detailed information from every stage of the pipeline and stores it in a dedicated branch:

```
deployment-reports/
├── 2025-08-10/
│   ├── run-16724235067/
│   │   ├── pipeline-logs.md
│   │   ├── build-logs.txt
│   │   ├── security-report.json
│   │   ├── deploy-output.log
│   │   └── cleanup-summary.md
│   └── run-16724235068/
│       └── pipeline-logs.md
├── 2025-08-11/
│   └── run-16724235069/
│       └── pipeline-logs.md
└── archive/
    └── 2025-07/
        └── logs-archive-2025-07.tar.gz
```

## Log Components

### 1. Pipeline Information Header

Every log file starts with comprehensive metadata:

- **Run ID**: Unique identifier for the pipeline execution
- **Run Number**: Sequential number of the run
- **Repository**: Full repository path
- **Branch**: Source branch that triggered the pipeline
- **Commit SHA**: Exact commit being deployed
- **Triggered By**: User or event that initiated the pipeline
- **Event Type**: push, pull_request, workflow_dispatch, etc.

### 2. Stage Logs

Each stage captures:

#### Build Stage
- Language detection results
- Dependency installation logs
- Test execution results
- Artifact creation details
- Build duration and status

#### Security Scanning
- CodeQL analysis results
- Dependency vulnerability scan
- Secret detection results
- Security recommendations

#### Quality Gates
- Code coverage metrics
- Code quality scores
- Linting results
- Quality gate decisions

#### Deployment
- Infrastructure provisioning logs
- Resource creation details
- Deployment retry attempts
- Endpoint URLs

#### Verification
- Health check results
- Smoke test outcomes
- Performance metrics
- API response times

#### Cleanup
- Resources cleaned
- Space freed
- Cost savings
- Retention policies applied

### 3. Summary Section

Consolidated view including:
- Overall pipeline status
- Total duration
- Stage-by-stage results
- Cost analysis
- Generated artifacts
- Next steps

## Accessing Logs

### Via GitHub UI

1. Navigate to your repository
2. Switch to the `deployment-reports` branch
3. Browse to `deployment-reports/YYYY-MM-DD/run-{ID}/`
4. Open `pipeline-logs.md`

### Via Git Command Line

```bash
# Checkout the logs branch
git fetch origin deployment-reports
git checkout deployment-reports

# View logs for a specific date
ls deployment-reports/2025-08-10/

# View specific pipeline run logs
cat deployment-reports/2025-08-10/run-16724235067/pipeline-logs.md
```

### Via Direct URL

```
https://github.com/{owner}/{repo}/blob/deployment-reports/deployment-reports/{date}/run-{id}/pipeline-logs.md
```

Example:
```
https://github.com/softengrahmed/webapp-demo/blob/deployment-reports/deployment-reports/2025-08-10/run-16724235067/pipeline-logs.md
```

## Log Retention

### Retention Policies

| Environment | Retention Period | Auto-Archive | Auto-Delete |
|-------------|-----------------|--------------|-------------|
| Development | 7 days | No | Yes |
| Staging | 14 days | Yes | Yes |
| Production | 30 days | Yes | No |
| Archive | 1 year | N/A | Yes |

### Archival Process

1. Logs older than retention period are compressed
2. Archives are stored in `deployment-reports/archive/`
3. Archive naming: `logs-archive-YYYY-MM.tar.gz`
4. Archives can be uploaded to S3 for long-term storage

## Log Analysis

### Quick Metrics Extraction

```bash
# Count successful deployments
grep -r "Status: SUCCESS" deployment-reports/ | wc -l

# Find average pipeline duration
grep -r "Total Duration:" deployment-reports/ | awk '{print $3}' | average.sh

# List all failed pipelines
grep -r "Status: FAILED" deployment-reports/ -l
```

### Common Patterns

#### Finding Deployment URLs
```bash
grep -r "Deployment URL:" deployment-reports/
```

#### Tracking Version Deployments
```bash
grep -r "Build Version:" deployment-reports/
```

#### Security Issue Tracking
```bash
grep -r "Critical Issues:" deployment-reports/
```

## Troubleshooting

### Missing Logs

If logs are missing:

1. Check if the pipeline completed
2. Verify the `deployment-reports` branch exists
3. Check GitHub Actions artifacts
4. Review pipeline permissions

### Incomplete Logs

If logs are incomplete:

1. Check if pipeline was cancelled
2. Review job-level failures
3. Check artifact upload status
4. Verify git push permissions

### Log Branch Issues

If the log branch has issues:

```bash
# Reset log branch
git checkout main
git branch -D deployment-reports
git checkout -b deployment-reports
git push origin deployment-reports --force
```

## Configuration

### Enable/Disable Logging

In `.github/workflows/cicd-main-pipeline-with-logging.yaml`:

```yaml
env:
  ENABLE_LOGGING: true  # Set to false to disable
  LOG_BRANCH: deployment-reports  # Change branch name
  LOG_RETENTION_DAYS: 30  # Adjust retention
```

### Customize Log Format

Modify `cicd-pipeline-configs/logging-config.yaml`:

```yaml
logging:
  format:
    type: markdown  # or json, yaml
    verbose: true   # Detailed logging
    timestamps: iso8601  # Timestamp format
```

### Add Custom Metrics

In any pipeline stage:

```yaml
- name: Custom Metric
  run: |
    echo "CUSTOM_LOG=${CUSTOM_LOG}#### My Custom Metric\\n" >> $GITHUB_ENV
    echo "CUSTOM_LOG=${CUSTOM_LOG}- Value: 42\\n" >> $GITHUB_ENV
```

## Best Practices

### 1. Consistent Formatting

- Use markdown headers for sections
- Include timestamps for all events
- Use emoji indicators for status
- Keep metrics in structured format

### 2. Security

- Never log secrets or credentials
- Sanitize sensitive data
- Use environment variable masking
- Review logs before committing

### 3. Performance

- Limit log file size to 10MB
- Archive old logs regularly
- Use compression for archives
- Clean up old branches

### 4. Maintenance

- Review logs weekly
- Archive monthly
- Update retention policies quarterly
- Monitor storage usage

## Integration

### With Monitoring Tools

```yaml
# Send logs to CloudWatch
- name: Push to CloudWatch
  run: |
    aws logs put-log-events \
      --log-group-name /aws/cicd/webapp-demo \
      --log-stream-name run-${{ github.run_id }} \
      --log-events file://pipeline-logs.json
```

### With Slack Notifications

```yaml
# Send log summary to Slack
- name: Notify Slack
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
      -H 'Content-Type: application/json' \
      -d '{"text":"Pipeline completed. Logs: https://github.com/${{ github.repository }}/blob/deployment-reports/..."}'
```

### With S3 Archival

```yaml
# Archive to S3
- name: Archive to S3
  run: |
    aws s3 cp deployment-reports/ \
      s3://webapp-demo-logs/pipeline/ \
      --recursive \
      --exclude "*.git*"
```

## Examples

### Sample Log Entry

```markdown
### 🔨 BUILD STAGE
**Started**: 2025-08-10T14:30:45Z

#### Language Detection
- Detected: **Node.js/JavaScript**
- Package Manager: Yarn

#### Environment Setup
- Installing Node.js dependencies...
- Dependencies installed: 47 production, 23 development
- Node version: v18.17.0
- NPM version: 9.6.7

#### Version Information
- Build Version: **v1.0.16724235067-a1b2c3d**
- Git Branch: main
- Git Commit: a1b2c3d4e5f6g7h8i9j0

#### Test Execution
- Test Status: ✅ **PASSED**
- Tests Run: 127
- Tests Passed: 127
- Test Coverage: 85.3%
- Test Duration: 45 seconds

**Completed**: 2025-08-10T14:32:30Z
**Duration**: 105 seconds
**Status**: success

---
```

## Support

For issues or questions about the logging system:

1. Check this documentation
2. Review the [pipeline configuration](../.github/workflows/cicd-main-pipeline-with-logging.yaml)
3. Open an issue in the repository
4. Contact the DevOps team

---

*Last Updated: 2025-08-10*
*Version: 1.0.0*