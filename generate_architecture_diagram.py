#!/usr/bin/env python3
"""
AWS CI/CD Pipeline Architecture Diagram Generator
Generates a visual representation of the webapp-demo CI/CD pipeline and AWS services

Requirements:
    pip install diagrams

Usage:
    python generate_architecture_diagram.py
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.aws.compute import Lambda, EC2
from diagrams.aws.database import RDS
from diagrams.aws.storage import S3
from diagrams.aws.monitoring import Cloudwatch
from diagrams.aws.security import IAM
from diagrams.aws.devtools import Codebuild, Codepipeline
from diagrams.aws.network import CloudFront, Route53
from diagrams.generic.device import Mobile, Tablet
from diagrams.generic.blank import Blank
from diagrams.programming.framework import React
from diagrams.programming.language import Nodejs
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.vcs import Github
from diagrams.onprem.database import PostgreSQL
from diagrams.onprem.client import Users
import os

def create_pipeline_architecture():
    """Create the CI/CD pipeline architecture diagram"""
    
    # Set diagram attributes
    graph_attr = {
        "fontsize": "20",
        "bgcolor": "white",
        "rankdir": "TB",
        "splines": "ortho",
        "nodesep": "1.0",
        "ranksep": "1.5"
    }
    
    node_attr = {
        "fontsize": "12",
        "fontname": "Arial"
    }
    
    edge_attr = {
        "fontsize": "10",
        "fontname": "Arial"
    }
    
    with Diagram(
        "Webapp Demo - AWS CI/CD Pipeline Architecture (Free Tier)",
        filename="webapp_demo_architecture",
        show=False,
        direction="TB",
        graph_attr=graph_attr,
        node_attr=node_attr,
        edge_attr=edge_attr
    ):
        
        # Users and clients
        users = Users("End Users")
        
        with Cluster("Development Environment"):
            github_repo = Github("GitHub Repository\n(webapp-demo)")
            
        with Cluster("CI/CD Pipeline (GitHub Actions)"):
            with Cluster("Pipeline Phases"):
                # Pre-build phase
                validation = GithubActions("Pre-build Validation\n• Repository Structure\n• Cost Compliance")
                
                # Build phase
                build = GithubActions("Build Phase\n• React Frontend\n• Express.js Backend\n• Artifact Creation")
                
                # Testing phase
                testing = GithubActions("Testing Suite\n• Unit Tests\n• Security Scans\n• Performance Tests")
                
                # Deployment phase
                deployment = GithubActions("Deployment Phase\n• Database Setup\n• Lambda Deploy\n• Frontend Deploy")
                
                # Monitoring phase
                monitoring = GithubActions("Monitoring Setup\n• CloudWatch Alarms\n• Health Checks")
        
        with Cluster("AWS Infrastructure (Free Tier)"):
            
            with Cluster("Identity & Access Management"):
                iam_roles = IAM("IAM Roles\n• CodeBuild Role\n• Lambda Execution Role")
            
            with Cluster("Frontend Hosting"):
                s3_frontend = S3("S3 Static Website\nwebapp-demo-frontend-*")
                
            with Cluster("Backend Services"):
                lambda_api = Lambda("Lambda Function\nwebapp-demo-api\n• Express.js Handler\n• Serverless Express")
                
            with Cluster("Database Layer"):
                rds_postgres = RDS("RDS PostgreSQL\ndb.t2.micro\n• 20GB Storage\n• Free Tier Compliant")
                
            with Cluster("Monitoring & Observability"):
                cloudwatch = Cloudwatch("CloudWatch\n• Lambda Metrics\n• Error Alarms\n• Duration Alarms")
                
        with Cluster("Application Components"):
            react_app = React("React Frontend\n• React Admin\n• TypeScript\n• NX Workspace")
            nodejs_api = Nodejs("Express.js API\n• TypeORM\n• CORS Enabled\n• PostgreSQL Driver")
            postgres_db = PostgreSQL("PostgreSQL DB\n• User Management\n• Application Data")
        
        # Define the pipeline flow
        pipeline_flow = [
            github_repo >> Edge(label="Push/PR", style="bold") >> validation,
            validation >> Edge(label="Structure OK") >> build,
            build >> Edge(label="Artifacts") >> testing,
            testing >> Edge(label="Tests Pass") >> deployment,
            deployment >> Edge(label="Resources Created") >> monitoring
        ]
        
        # Infrastructure connections
        infrastructure_connections = [
            deployment >> Edge(label="Creates", style="dashed") >> iam_roles,
            deployment >> Edge(label="Deploys", color="blue") >> s3_frontend,
            deployment >> Edge(label="Deploys", color="green") >> lambda_api,
            deployment >> Edge(label="Provisions", color="purple") >> rds_postgres,
            monitoring >> Edge(label="Configures", color="orange") >> cloudwatch
        ]
        
        # Application layer connections
        app_connections = [
            react_app >> Edge(label="Builds to") >> s3_frontend,
            nodejs_api >> Edge(label="Packages to") >> lambda_api,
            postgres_db >> Edge(label="Connects to") >> rds_postgres
        ]
        
        # Runtime connections
        runtime_connections = [
            users >> Edge(label="HTTPS Requests", color="darkgreen", style="bold") >> s3_frontend,
            s3_frontend >> Edge(label="API Calls", color="darkblue") >> lambda_api,
            lambda_api >> Edge(label="Database Queries", color="darkred") >> rds_postgres,
            cloudwatch >> Edge(label="Monitors", style="dotted") >> lambda_api,
            cloudwatch >> Edge(label="Monitors", style="dotted") >> rds_postgres
        ]
        
        # Service monitoring
        monitoring_connections = [
            lambda_api >> Edge(label="Logs/Metrics", style="dotted", color="gray") >> cloudwatch,
            rds_postgres >> Edge(label="DB Metrics", style="dotted", color="gray") >> cloudwatch
        ]

def create_cost_breakdown_diagram():
    """Create a cost breakdown diagram for the free tier services"""
    
    with Diagram(
        "AWS Free Tier Cost Breakdown",
        filename="aws_free_tier_costs",
        show=False,
        direction="LR"
    ):
        
        with Cluster("Free Tier Services ($0.00/month)"):
            
            with Cluster("Compute"):
                lambda_cost = Lambda("AWS Lambda\n• 1M requests/month FREE\n• 400K GB-seconds FREE")
                
            with Cluster("Storage"):
                s3_cost = S3("Amazon S3\n• 5 GB storage FREE\n• 20K GET requests FREE\n• 2K PUT requests FREE")
                
            with Cluster("Database"):
                rds_cost = RDS("RDS PostgreSQL\n• db.t2.micro FREE\n• 750 hours/month (12 months)\n• 20 GB storage FREE")
                
            with Cluster("Monitoring"):
                cloudwatch_cost = Cloudwatch("CloudWatch\n• 10 custom metrics FREE\n• 10 alarms FREE\n• Basic monitoring FREE")
                
            with Cluster("CI/CD"):
                codebuild_cost = Codebuild("GitHub Actions\n• 2,000 minutes/month FREE\n• Public repositories")

def create_deployment_flow_diagram():
    """Create a detailed deployment flow diagram"""
    
    with Diagram(
        "CI/CD Deployment Flow",
        filename="deployment_flow",
        show=False,
        direction="TB"
    ):
        
        # Source control
        source = Github("Source Code\n(React + Express)")
        
        with Cluster("GitHub Actions Workflow"):
            # Pre-build
            pre_build = GithubActions("1. Pre-build Validation")
            
            # Environment setup
            env_setup = GithubActions("2. Environment Setup")
            
            # Build
            build_step = GithubActions("3. Build & Test")
            
            # Database
            db_setup = GithubActions("4. Database Setup")
            
            # Backend deployment
            backend_deploy = GithubActions("5. Lambda Deployment")
            
            # Frontend deployment
            frontend_deploy = GithubActions("6. Frontend Deployment")
            
            # Validation
            validation_step = GithubActions("7. Deployment Validation")
            
            # Reporting
            reporting = GithubActions("8. Cost Analysis & Reporting")
        
        # AWS Resources
        with Cluster("AWS Resources"):
            lambda_func = Lambda("Lambda API")
            s3_bucket = S3("S3 Website")
            rds_db = RDS("PostgreSQL DB")
            monitoring = Cloudwatch("CloudWatch")
        
        # Flow connections
        source >> pre_build >> env_setup >> build_step >> db_setup
        db_setup >> backend_deploy >> frontend_deploy >> validation_step >> reporting
        
        # Deployment connections
        db_setup >> rds_db
        backend_deploy >> lambda_func
        frontend_deploy >> s3_bucket
        validation_step >> monitoring

def generate_html_report():
    """Generate an HTML report with embedded diagrams"""
    
    html_content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Webapp Demo - CI/CD Pipeline Architecture Report</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                line-height: 1.6;
                margin: 0;
                padding: 20px;
                background-color: #f5f5f5;
            }
            .container {
                max-width: 1200px;
                margin: 0 auto;
                background: white;
                border-radius: 10px;
                box-shadow: 0 0 20px rgba(0,0,0,0.1);
                overflow: hidden;
            }
            .header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 30px;
                text-align: center;
            }
            .header h1 {
                margin: 0;
                font-size: 2.5em;
            }
            .header p {
                margin: 10px 0 0 0;
                font-size: 1.2em;
                opacity: 0.9;
            }
            .section {
                padding: 30px;
                border-bottom: 1px solid #eee;
            }
            .section:last-child {
                border-bottom: none;
            }
            .section h2 {
                color: #333;
                border-bottom: 2px solid #667eea;
                padding-bottom: 10px;
                margin-bottom: 20px;
            }
            .diagram-container {
                text-align: center;
                margin: 20px 0;
                padding: 20px;
                background: #f9f9f9;
                border-radius: 5px;
            }
            .cost-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
                gap: 20px;
                margin: 20px 0;
            }
            .cost-item {
                background: #f8f9fa;
                padding: 20px;
                border-radius: 5px;
                border-left: 4px solid #28a745;
            }
            .cost-item h3 {
                margin: 0 0 10px 0;
                color: #333;
            }
            .cost-item .price {
                font-size: 1.5em;
                font-weight: bold;
                color: #28a745;
            }
            .pipeline-steps {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 15px;
                margin: 20px 0;
            }
            .step {
                background: #e3f2fd;
                padding: 15px;
                border-radius: 5px;
                border-left: 4px solid #2196f3;
            }
            .step h4 {
                margin: 0 0 10px 0;
                color: #1976d2;
            }
            .tech-stack {
                display: flex;
                flex-wrap: wrap;
                gap: 10px;
                margin: 20px 0;
            }
            .tech {
                background: #fff3e0;
                padding: 8px 16px;
                border-radius: 20px;
                border: 1px solid #ff9800;
                color: #e65100;
                font-weight: bold;
            }
            .endpoints {
                background: #e8f5e8;
                padding: 20px;
                border-radius: 5px;
                margin: 20px 0;
            }
            .endpoints h3 {
                color: #2e7d32;
                margin: 0 0 15px 0;
            }
            .endpoint {
                margin: 10px 0;
                padding: 10px;
                background: white;
                border-radius: 3px;
                border-left: 4px solid #4caf50;
            }
            .cleanup-options {
                background: #fff3e0;
                padding: 20px;
                border-radius: 5px;
                margin: 20px 0;
            }
            .cleanup-options h3 {
                color: #f57c00;
                margin: 0 0 15px 0;
            }
            .option {
                margin: 10px 0;
                padding: 10px;
                background: white;
                border-radius: 3px;
                border-left: 4px solid #ff9800;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🚀 Webapp Demo CI/CD Pipeline</h1>
                <p>Comprehensive Architecture & Cost Analysis Report</p>
                <p>AWS Free Tier Deployment | Generated: July 30, 2025</p>
            </div>
            
            <div class="section">
                <h2>📊 Executive Summary</h2>
                <p>This report details the successful implementation of a comprehensive CI/CD pipeline for the webapp-demo project, designed specifically for AWS Free Tier deployment. The pipeline follows enterprise-grade practices while maintaining zero cost through careful service selection and resource optimization.</p>
                
                <div class="tech-stack">
                    <span class="tech">React</span>
                    <span class="tech">Express.js</span>
                    <span class="tech">PostgreSQL</span>
                    <span class="tech">AWS Lambda</span>
                    <span class="tech">Amazon S3</span>
                    <span class="tech">Amazon RDS</span>
                    <span class="tech">GitHub Actions</span>
                    <span class="tech">CloudWatch</span>
                    <span class="tech">TypeScript</span>
                    <span class="tech">NX Workspace</span>
                </div>
            </div>
            
            <div class="section">
                <h2>🏗️ Architecture Overview</h2>
                <div class="diagram-container">
                    <h3>Main Architecture Diagram</h3>
                    <p>The diagram below shows the complete CI/CD pipeline architecture and AWS service connections:</p>
                    <p><em>Note: Run the Python script to generate actual diagrams: <code>python generate_architecture_diagram.py</code></em></p>
                </div>
                
                <div class="pipeline-steps">
                    <div class="step">
                        <h4>1. Pre-build Validation</h4>
                        <p>Repository structure validation and cost compliance checks</p>
                    </div>
                    <div class="step">
                        <h4>2. Environment Setup</h4>
                        <p>Node.js environment, AWS credentials, and dependency installation</p>
                    </div>
                    <div class="step">
                        <h4>3. Build & Test</h4>
                        <p>React frontend and Express.js backend compilation with comprehensive testing</p>
                    </div>
                    <div class="step">
                        <h4>4. Database Setup</h4>
                        <p>RDS PostgreSQL instance provisioning with free tier configuration</p>
                    </div>
                    <div class="step">
                        <h4>5. Backend Deployment</h4>
                        <p>Lambda function deployment with serverless Express.js handler</p>
                    </div>
                    <div class="step">
                        <h4>6. Frontend Deployment</h4>
                        <p>S3 static website hosting with public read access</p>
                    </div>
                    <div class="step">
                        <h4>7. Monitoring Setup</h4>
                        <p>CloudWatch alarms for error rates and performance monitoring</p>
                    </div>
                    <div class="step">
                        <h4>8. Validation & Reporting</h4>
                        <p>Health checks, cost analysis, and comprehensive reporting</p>
                    </div>
                </div>
            </div>
            
            <div class="section">
                <h2>💰 Cost Analysis (Free Tier)</h2>
                <div class="cost-grid">
                    <div class="cost-item">
                        <h3>Amazon S3</h3>
                        <div class="price">$0.00/month</div>
                        <p>5 GB storage, 20K GET requests, 2K PUT requests included in free tier</p>
                    </div>
                    <div class="cost-item">
                        <h3>AWS Lambda</h3>
                        <div class="price">$0.00/month</div>
                        <p>1M requests and 400K GB-seconds of compute time included</p>
                    </div>
                    <div class="cost-item">
                        <h3>Amazon RDS</h3>
                        <div class="price">$0.00/month</div>
                        <p>750 hours of db.t2.micro and 20 GB storage (12 months free)</p>
                    </div>
                    <div class="cost-item">
                        <h3>CloudWatch</h3>
                        <div class="price">$0.00/month</div>
                        <p>10 custom metrics, 10 alarms, and basic monitoring included</p>
                    </div>
                    <div class="cost-item">
                        <h3>GitHub Actions</h3>
                        <div class="price">$0.00/month</div>
                        <p>2,000 minutes per month for public repositories</p>
                    </div>
                    <div class="cost-item">
                        <h3>Total Monthly Cost</h3>
                        <div class="price">$0.00/month</div>
                        <p>All services within AWS Free Tier limits</p>
                    </div>
                </div>
            </div>
            
            <div class="section">
                <h2>🌐 Deployment Endpoints</h2>
                <div class="endpoints">
                    <h3>Application URLs</h3>
                    <div class="endpoint">
                        <strong>Frontend URL:</strong><br>
                        <code>http://webapp-demo-frontend-073651099697.s3-website-us-east-1.amazonaws.com</code><br>
                        <em>React application hosted on S3 static website</em>
                    </div>
                    <div class="endpoint">
                        <strong>API Endpoint:</strong><br>
                        <code>Generated during Lambda deployment</code><br>
                        <em>Express.js API running on AWS Lambda with Function URLs</em>
                    </div>
                    <div class="endpoint">
                        <strong>Database Connection:</strong><br>
                        <code>RDS PostgreSQL endpoint (private)</code><br>
                        <em>Database accessible only from Lambda functions</em>
                    </div>
                </div>
            </div>
            
            <div class="section">
                <h2>🧹 Resource Cleanup Options</h2>
                <div class="cleanup-options">
                    <h3>Cost Optimization Strategies</h3>
                    <div class="option">
                        <strong>Immediately:</strong> Delete all resources right after validation to minimize any potential costs
                    </div>
                    <div class="option">
                        <strong>15-60 minutes:</strong> Scheduled cleanup allowing for testing and validation
                    </div>
                    <div class="option">
                        <strong>No cleanup:</strong> Keep resources active for continued development (recommended for learning)
                    </div>
                </div>
                <p><strong>Recommendation:</strong> For production use, implement the scheduled cleanup. For learning and development, keep resources active as they remain within free tier limits.</p>
            </div>
            
            <div class="section">
                <h2>📈 Performance Metrics & Monitoring</h2>
                <p>The pipeline includes comprehensive monitoring setup:</p>
                <ul>
                    <li><strong>Lambda Error Rate Monitoring:</strong> Alarms trigger if error rate exceeds 5 errors in 10 minutes</li>
                    <li><strong>Lambda Duration Monitoring:</strong> Alerts for functions taking longer than 25 seconds</li>
                    <li><strong>Database Connection Monitoring:</strong> RDS performance insights for query optimization</li>
                    <li><strong>S3 Request Monitoring:</strong> Track frontend access patterns and performance</li>
                </ul>
            </div>
            
            <div class="section">
                <h2>🔒 Security & Compliance</h2>
                <p>Security features implemented in the pipeline:</p>
                <ul>
                    <li><strong>IAM Roles:</strong> Least privilege access for CodeBuild and Lambda execution</li>
                    <li><strong>Security Scanning:</strong> Automated vulnerability assessment in CI/CD pipeline</li>
                    <li><strong>Environment Variables:</strong> Secure handling of database credentials and API keys</li>
                    <li><strong>CORS Configuration:</strong> Proper cross-origin resource sharing setup</li>
                    <li><strong>Input Validation:</strong> TypeORM and Express.js security middleware</li>
                </ul>
            </div>
            
            <div class="section">
                <h2>🚀 Next Steps</h2>
                <ol>
                    <li><strong>Execute Pipeline:</strong> Run the GitHub Actions workflow manually or via push to trigger deployment</li>
                    <li><strong>Monitor Deployment:</strong> Track progress in GitHub Actions and AWS CloudWatch</li>
                    <li><strong>Validate Endpoints:</strong> Test frontend and API functionality after deployment</li>
                    <li><strong>Review Logs:</strong> Check Lambda function logs and performance metrics</li>
                    <li><strong>Optimize Performance:</strong> Use CloudWatch insights to identify optimization opportunities</li>
                    <li><strong>Plan Scaling:</strong> When ready to move beyond free tier, consider ECS/Fargate for backend</li>
                </ol>
            </div>
            
            <div class="section">
                <h2>📞 Support & Resources</h2>
                <p><strong>GitHub Repository:</strong> <a href="https://github.com/softengrahmed/webapp-demo">webapp-demo</a></p>
                <p><strong>Pipeline Status:</strong> <a href="https://github.com/softengrahmed/webapp-demo/issues/2">GitHub Issue #2</a></p>
                <p><strong>AWS Documentation:</strong> <a href="https://docs.aws.amazon.com/free/">AWS Free Tier Guide</a></p>
                <p><strong>Architecture Diagrams:</strong> Run <code>python generate_architecture_diagram.py</code> to create visual diagrams</p>
            </div>
        </div>
    </body>
    </html>
    """
    
    with open("pipeline_architecture_report.html", "w", encoding="utf-8") as f:
        f.write(html_content)

def main():
    """Main function to generate all diagrams and reports"""
    print("🎨 Generating AWS CI/CD Pipeline Architecture Diagrams...")
    
    try:
        # Generate architecture diagrams
        create_pipeline_architecture()
        print("✅ Main architecture diagram created: webapp_demo_architecture.png")
        
        create_cost_breakdown_diagram()
        print("✅ Cost breakdown diagram created: aws_free_tier_costs.png")
        
        create_deployment_flow_diagram()
        print("✅ Deployment flow diagram created: deployment_flow.png")
        
        # Generate HTML report
        generate_html_report()
        print("✅ HTML report generated: pipeline_architecture_report.html")
        
        print("\n🎯 All diagrams and reports generated successfully!")
        print("\nFiles created:")
        print("  • webapp_demo_architecture.png - Main architecture diagram")
        print("  • aws_free_tier_costs.png - Cost breakdown visualization")
        print("  • deployment_flow.png - CI/CD deployment flow")
        print("  • pipeline_architecture_report.html - Comprehensive HTML report")
        
        print("\n📋 To view the diagrams:")
        print("  1. Open the PNG files in any image viewer")
        print("  2. Open pipeline_architecture_report.html in a web browser")
        print("  3. The HTML report contains all details about the pipeline")
        
    except ImportError as e:
        print("❌ Error: Missing required package 'diagrams'")
        print("💡 Install with: pip install diagrams")
        print("📦 Also requires Graphviz: https://graphviz.org/download/")
    except Exception as e:
        print(f"❌ Error generating diagrams: {e}")
        print("💡 Make sure you have 'diagrams' package installed and Graphviz configured")

if __name__ == "__main__":
    main()
