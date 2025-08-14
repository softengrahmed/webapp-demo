#!/bin/bash

# AWS Serverless Deployment Script
# Run this script in AWS CloudShell or CodeBuild
# Usage: ./scripts/deploy.sh [staging|production]

set -e

# Configuration
ENVIRONMENT=${1:-staging}
AWS_REGION=${AWS_REGION:-us-east-1}
APP_NAME="webapp-demo"
BUILD_ID=${BUILD_ID:-$(date +%Y%m%d%H%M%S)}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Starting deployment to ${ENVIRONMENT}${NC}"

# Validate environment
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    echo -e "${RED}Error: Invalid environment. Use 'staging' or 'production'${NC}"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &>/dev/null; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}AWS Account: ${AWS_ACCOUNT_ID}${NC}"

# Create IAM role for Lambda if not exists
ROLE_NAME="${APP_NAME}-lambda-role"
ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"

echo -e "${YELLOW}Creating IAM role...${NC}"
aws iam create-role \
    --role-name ${ROLE_NAME} \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [{
            "Effect": "Allow",
            "Principal": {"Service": "lambda.amazonaws.com"},
            "Action": "sts:AssumeRole"
        }]
    }' 2>/dev/null || echo "Role already exists"

# Attach policies to role
aws iam attach-role-policy \
    --role-name ${ROLE_NAME} \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
    2>/dev/null || true

aws iam attach-role-policy \
    --role-name ${ROLE_NAME} \
    --policy-arn arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess \
    2>/dev/null || true

# Wait for role to be ready
sleep 10

# Deploy Frontend to S3
echo -e "${YELLOW}Deploying frontend to S3...${NC}"

if [ "$ENVIRONMENT" = "production" ]; then
    BUCKET_NAME="${APP_NAME}-production"
else
    BUCKET_NAME="${APP_NAME}-staging-${BUILD_ID}"
fi

# Create S3 bucket
aws s3 mb s3://${BUCKET_NAME} --region ${AWS_REGION} 2>/dev/null || true

# Enable static website hosting
aws s3 website s3://${BUCKET_NAME} \
    --index-document index.html \
    --error-document error.html

# Set bucket policy for public access
aws s3api put-bucket-policy --bucket ${BUCKET_NAME} --policy "{
    \"Version\": \"2012-10-17\",
    \"Statement\": [{
        \"Sid\": \"PublicReadGetObject\",
        \"Effect\": \"Allow\",
        \"Principal\": \"*\",
        \"Action\": \"s3:GetObject\",
        \"Resource\": \"arn:aws:s3:::${BUCKET_NAME}/*\"
    }]
}"

# Upload frontend files
if [ -d "dist/apps/app" ]; then
    aws s3 sync dist/apps/app/ s3://${BUCKET_NAME} \
        --delete \
        --cache-control "public, max-age=3600"
fi

FRONTEND_URL="http://${BUCKET_NAME}.s3-website-${AWS_REGION}.amazonaws.com"
echo -e "${GREEN}Frontend deployed to: ${FRONTEND_URL}${NC}"

# Deploy API to Lambda
echo -e "${YELLOW}Deploying API to Lambda...${NC}"

FUNCTION_NAME="${APP_NAME}-api-${ENVIRONMENT}"

# Package API code
if [ -d "dist/apps/api" ]; then
    cd dist/apps/api
    zip -r function.zip .
    
    # Create or update Lambda function
    if aws lambda get-function --function-name ${FUNCTION_NAME} &>/dev/null; then
        echo "Updating existing Lambda function..."
        aws lambda update-function-code \
            --function-name ${FUNCTION_NAME} \
            --zip-file fileb://function.zip
        
        aws lambda update-function-configuration \
            --function-name ${FUNCTION_NAME} \
            --environment Variables={NODE_ENV=${ENVIRONMENT},FRONTEND_URL=${FRONTEND_URL}}
    else
        echo "Creating new Lambda function..."
        aws lambda create-function \
            --function-name ${FUNCTION_NAME} \
            --runtime nodejs16.x \
            --role ${ROLE_ARN} \
            --handler main.handler \
            --zip-file fileb://function.zip \
            --timeout 30 \
            --memory-size 512 \
            --environment Variables={NODE_ENV=${ENVIRONMENT},FRONTEND_URL=${FRONTEND_URL}}
    fi
    
    # Create or get function URL
    API_URL=$(aws lambda get-function-url-config \
        --function-name ${FUNCTION_NAME} \
        --query 'FunctionUrl' --output text 2>/dev/null || \
    aws lambda create-function-url-config \
        --function-name ${FUNCTION_NAME} \
        --auth-type NONE \
        --cors '{
            "AllowOrigins": ["*"],
            "AllowMethods": ["*"],
            "AllowHeaders": ["*"]
        }' \
        --query 'FunctionUrl' --output text)
    
    cd -
fi

echo -e "${GREEN}API deployed to: ${API_URL}${NC}"

# Create API Gateway (optional - for production)
if [ "$ENVIRONMENT" = "production" ]; then
    echo -e "${YELLOW}Setting up API Gateway...${NC}"
    
    API_NAME="${APP_NAME}-api"
    
    # Create REST API
    API_ID=$(aws apigateway create-rest-api \
        --name ${API_NAME} \
        --description "Production API for ${APP_NAME}" \
        --query 'id' --output text 2>/dev/null || \
    aws apigateway get-rest-apis \
        --query "items[?name=='${API_NAME}'].id" --output text | head -1)
    
    if [ -n "$API_ID" ]; then
        API_GATEWAY_URL="https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/prod"
        echo -e "${GREEN}API Gateway: ${API_GATEWAY_URL}${NC}"
    fi
fi

# Output deployment summary
echo -e "\n${GREEN}=== Deployment Summary ===${NC}"
echo -e "Environment: ${ENVIRONMENT}"
echo -e "Build ID: ${BUILD_ID}"
echo -e "Frontend URL: ${FRONTEND_URL}"
echo -e "API URL: ${API_URL}"
if [ -n "${API_GATEWAY_URL}" ]; then
    echo -e "API Gateway URL: ${API_GATEWAY_URL}"
fi
echo -e "${GREEN}=========================${NC}"

# Save deployment info
cat > deployment-info.json <<EOF
{
    "environment": "${ENVIRONMENT}",
    "buildId": "${BUILD_ID}",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "frontend": {
        "url": "${FRONTEND_URL}",
        "bucket": "${BUCKET_NAME}"
    },
    "api": {
        "url": "${API_URL}",
        "function": "${FUNCTION_NAME}"
    },
    "region": "${AWS_REGION}",
    "account": "${AWS_ACCOUNT_ID}"
}
EOF

echo -e "\n${GREEN}✅ Deployment completed successfully!${NC}"