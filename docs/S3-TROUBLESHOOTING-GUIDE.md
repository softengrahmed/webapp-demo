# 🪣 S3 Troubleshooting Guide

This guide covers common S3 issues encountered during webapp deployment, particularly focusing on Block Public Access settings and bucket policy configurations.

## 🚨 Common Issue: Block Public Access Policy Error

### Error Message
```
An error occurred (AccessDenied) when calling the PutBucketPolicy operation: 
User: arn:aws:iam::ACCOUNT:user/automation/react-pipeline-user is not authorized 
to perform: s3:PutBucketPolicy on resource: "arn:aws:s3:::BUCKET-NAME" because 
public policies are blocked by the BlockPublicPolicy block public access setting.
```

### Root Cause
The S3 bucket has **Block Public Access** settings enabled, which prevents the application of bucket policies that would grant public read access. This is a security feature that blocks potentially dangerous public access configurations.

## 🛠️ Solutions

### Solution 1: Update Block Public Access Settings (Recommended for Static Websites)

If your bucket is meant to serve a public static website, you need to modify the Block Public Access settings:

```bash
# Check current settings
aws s3api get-public-access-block --bucket YOUR-BUCKET-NAME

# Update settings to allow public policies but block public ACLs
aws s3api put-public-access-block --bucket YOUR-BUCKET-NAME \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=false,RestrictPublicBuckets=false

# Verify changes
aws s3api get-public-access-block --bucket YOUR-BUCKET-NAME
```

**Settings Explanation:**
- `BlockPublicAcls=true`: Prevents new public ACLs (recommended for security)
- `IgnorePublicAcls=true`: Ignores existing public ACLs (recommended for security)
- `BlockPublicPolicy=false`: **Allows bucket policies with public access** (required for static websites)
- `RestrictPublicBuckets=false`: **Allows public read access** (required for static websites)

### Solution 2: Use CloudFront with Origin Access Control (More Secure)

For enhanced security, use CloudFront with OAC instead of public bucket policies:

```bash
# Keep all Block Public Access settings enabled
aws s3api put-public-access-block --bucket YOUR-BUCKET-NAME \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# Create CloudFront distribution with OAC
# (Implementation details would be in CloudFormation/Terraform)
```

## 🔧 Workflow Integration

Our updated workflow now includes automatic Block Public Access configuration:

```yaml
- name: 🔧 Configure S3 Block Public Access
  run: |
    BUCKET_NAME="webapp-demo-${{ github.event.inputs.environment }}-frontend"
    
    echo "🔐 Configuring Block Public Access for static website hosting..."
    aws s3api put-public-access-block \
      --bucket $BUCKET_NAME \
      --public-access-block-configuration \
      BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=false,RestrictPublicBuckets=false
    
    # Verify configuration
    aws s3api get-public-access-block --bucket $BUCKET_NAME
```

## 📋 Pre-Deployment Checklist

Before running your deployment pipeline, ensure:

- [ ] **AWS Permissions**: Your IAM user has `s3:PutPublicAccessBlock` permissions
- [ ] **Bucket Policy**: Your policy grants only necessary public read access
- [ ] **Security Review**: You understand the security implications of public access
- [ ] **Monitoring**: CloudTrail is enabled to monitor S3 access changes

## 🛡️ Security Best Practices

### ✅ Recommended Configuration for Static Websites
```json
{
  "BlockPublicAcls": true,
  "IgnorePublicAcls": true, 
  "BlockPublicPolicy": false,
  "RestrictPublicBuckets": false
}
```

### 🚫 What This Prevents
- **Public ACLs**: Blocks accidentally making objects public via ACLs
- **ACL Overrides**: Ignores any existing public ACLs
- **Allows Policies**: Permits bucket policies for controlled public access
- **Allows Reading**: Permits public read access for website functionality

## 🔍 Troubleshooting Commands

### Check Current Block Public Access Settings
```bash
aws s3api get-public-access-block --bucket YOUR-BUCKET-NAME
```

### Verify Bucket Policy
```bash
aws s3api get-bucket-policy --bucket YOUR-BUCKET-NAME
```

### Test Website Access
```bash
# Get website endpoint
aws s3api get-bucket-website --bucket YOUR-BUCKET-NAME

# Test public access
curl -I http://YOUR-BUCKET-NAME.s3-website-us-east-1.amazonaws.com
```

### Check IAM Permissions
```bash
# Simulate policy evaluation
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT:user/YOUR-USER \
  --action-names s3:PutBucketPolicy s3:PutPublicAccessBlock \
  --resource-arns arn:aws:s3:::YOUR-BUCKET-NAME
```

## 🚨 Emergency Recovery

If your website becomes inaccessible after configuration changes:

1. **Immediate Fix**:
   ```bash
   # Restore working configuration
   aws s3api put-public-access-block --bucket YOUR-BUCKET-NAME \
     --public-access-block-configuration \
     BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=false,RestrictPublicBuckets=false
   ```

2. **Verify Policy**:
   ```bash
   # Re-apply bucket policy if needed
   aws s3api put-bucket-policy --bucket YOUR-BUCKET-NAME --policy file://bucket-policy.json
   ```

3. **Test Access**:
   ```bash
   curl -I http://YOUR-BUCKET-NAME.s3-website-us-east-1.amazonaws.com
   ```

## 📞 Support

If you continue experiencing issues:

1. Check the [AWS Service Health Dashboard](https://status.aws.amazon.com/)
2. Review CloudTrail logs for detailed error information
3. Verify your AWS account permissions and quotas
4. Consider using AWS Support if you have a support plan

## 📚 Additional Resources

- [AWS S3 Block Public Access Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html)
- [S3 Static Website Hosting Guide](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront with S3 Security Best Practices](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)

---

**Last Updated**: August 4, 2025  
**Status**: ✅ Resolved - S3 Block Public Access configuration updated