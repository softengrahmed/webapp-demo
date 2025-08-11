# Cleanup Strategy Guide

## Overview

This guide documents the comprehensive cleanup strategies implemented in the CI/CD pipeline to optimize resource usage and reduce costs.

## Cleanup Stages

### 1. Workspace Cleanup
**Frequency**: After every pipeline run
**Resources Cleaned**:
- Build artifacts (`dist/`)
- Node modules (`node_modules/`)
- Coverage reports (`coverage/`)
- Temporary files (`*.tmp`, `*.log`)
- Cache directories (`.cache/`, `.next/`)

### 2. Docker Cleanup
**Frequency**: After every pipeline run
**Resources Cleaned**:
- Stopped containers
- Unused images
- Dangling volumes
- Unused networks
- Build cache

### 3. GitHub Artifacts Cleanup
**Frequency**: Daily
**Retention Policy**:
- Development: 7 days
- Staging: 14 days
- Production: 30 days

### 4. AWS Resources Cleanup (Optional)
**Frequency**: Configurable
**Resources Cleaned**:
- Temporary Lambda functions
- Unused S3 objects
- Old CloudWatch logs
- Temporary IAM roles

## Configuration

### Retention Policies

```yaml
retention_policies:
  development:
    artifacts: 7
    logs: 7
    cache: 3
  
  staging:
    artifacts: 14
    logs: 14
    cache: 7
  
  production:
    artifacts: 30
    logs: 90
    cache: 14
```

### Cleanup Triggers

1. **Automatic**: Runs after every pipeline execution
2. **Scheduled**: Daily cleanup job at 2 AM UTC
3. **Manual**: Can be triggered via workflow dispatch
4. **On-Demand**: Triggered when storage limits approached

## Safety Measures

### Protected Resources
- Production deployments
- Active database snapshots
- Audit logs
- Compliance-related artifacts

### Dry Run Mode
Test cleanup without actual deletion:
```bash
gh workflow run cleanup-stage.yaml -f dry_run=true
```

## Cost Optimization

### Estimated Savings
- **Storage**: 60-70% reduction
- **Compute**: 20-30% reduction
- **Network**: 10-15% reduction

### Monthly Cost Impact
- Before cleanup: ~$50-100
- After cleanup: ~$15-30
- **Savings: 70%**

## Monitoring

### Metrics Tracked
- Resources cleaned per run
- Storage space recovered
- Cleanup execution time
- Failed cleanup attempts

### Alerts
- Cleanup failures
- Storage threshold exceeded
- Unusual resource growth

## Best Practices

1. **Regular Reviews**: Monthly review of retention policies
2. **Gradual Rollout**: Test cleanup in dev before prod
3. **Backup Critical**: Always backup critical artifacts
4. **Monitor Impact**: Track performance after cleanup
5. **Document Changes**: Log all policy modifications

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   Solution: Check IAM roles and GitHub permissions
   ```

2. **Resource In Use**
   ```bash
   Solution: Wait for active processes to complete
   ```

3. **Quota Exceeded**
   ```bash
   Solution: Increase cleanup frequency or reduce retention
   ```

## Emergency Procedures

### Restore Deleted Artifacts
1. Check GitHub Actions history
2. Use artifact recovery API
3. Restore from backup if available

### Disable Cleanup
```yaml
# In main pipeline
cleanup:
  enabled: false
```

## Compliance

### Audit Requirements
- Keep audit logs for 7 years
- Retain deployment artifacts for 90 days
- Document all cleanup activities

### Data Retention Laws
- GDPR: Personal data handling
- SOC2: Security artifact retention
- HIPAA: Healthcare data requirements

## Future Improvements

1. **Machine Learning**: Predictive cleanup based on usage patterns
2. **Smart Retention**: Dynamic retention based on artifact importance
3. **Cross-Region**: Multi-region cleanup coordination
4. **Cost Analytics**: Detailed cost impact reporting

## Support

For cleanup-related issues:
- Check cleanup logs in GitHub Actions
- Review cleanup-report artifacts
- Contact DevOps team for assistance