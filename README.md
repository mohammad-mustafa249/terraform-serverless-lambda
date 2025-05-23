# *Terraform: Serverless Container Infrastructure on AWS*

This repo provisions a serverless infrastructure using **Terraform**, deploying a **container-based Lambda function** behind **API Gateway**, inside a **VPC with public/private subnets**.

---

## Features
- AWS Lambda (container runtime)
- API Gateway HTTP trigger
- VPC with 2 public and 2 private subnets
- Lambda runs inside private subnets with outbound internet access
- Docker image hosted in ECR (Elastic Container Registry)

---

## Prerequisites

- AWS CLI configured (`aws configure`)
- Docker installed
- Terraform v1.3+ installed
- IAM user with required permissions (see below)

---

## Required IAM Permissions

The IAM user or role running Terraform must have the following permissions:

### VPC / Networking

- `ec2:CreateVpc`
- `ec2:CreateSubnet`
- `ec2:CreateInternetGateway`
- `ec2:CreateNatGateway`
- `ec2:AllocateAddress`
- `ec2:CreateRouteTable`
- `ec2:CreateRoute`
- `ec2:AssociateRouteTable`
- `ec2:DescribeAvailabilityZones`
- `ec2:DescribeSubnets`
- `ec2:CreateSecurityGroup`
- `ec2:AuthorizeSecurityGroupEgress`

### Lambda

- `lambda:CreateFunction`
- `lambda:UpdateFunctionCode`
- `lambda:UpdateFunctionConfiguration`
- `lambda:CreateFunctionUrlConfig`
- `lambda:DeleteFunction`
- `lambda:GetFunction`
- `lambda:AddPermission`

### IAM

- `iam:CreateRole`
- `iam:PutRolePolicy`
- `iam:AttachRolePolicy`
- `iam:PassRole`
- `iam:GetRole`
- `iam:DeleteRole`

### API Gateway (HTTP APIs)

- `apigatewayv2:CreateApi`
- `apigatewayv2:CreateRoute`
- `apigatewayv2:CreateStage`
- `apigatewayv2:CreateIntegration`
- `apigatewayv2:UpdateApi`
- `apigatewayv2:DeleteApi`
- `apigatewayv2:TagResource`

### ECR

- `ecr:GetAuthorizationToken`
- `ecr:CreateRepository`
- `ecr:BatchCheckLayerAvailability`
- `ecr:PutImage`
- `ecr:InitiateLayerUpload`
- `ecr:UploadLayerPart`
- `ecr:CompleteLayerUpload`

 ## Alternatively, you can attach these AWS Managed Policies:

- `AmazonEC2FullAccess`
- `AmazonVPCFullAccess`
- `AmazonECRFullAccess`
- `AWSLambda_FullAccess`
- `IAMFullAccess`
- `AmazonAPIGatewayAdministrator`

---

## Things You Must Replace

| Location | Placeholder | Replace With |
|----------|-------------|---------------|
| CLI / Terraform | `<aws_account_id>` | Your 12-digit AWS Account ID |
| CLI / Terraform | `<region>` | Your AWS Region (e.g. `us-east-1`) |
| Terraform var | `<your-ecr-image-uri>` | ECR image URI (after Docker push) |

---

## Step-by-Step Deployment

## Clone the Repo

git clone https://github.com/<your-user>/terraform-serverless-container.git
cd terraform-serverless-container

## Build and Push Docker Image to ECR

## a. Create ECR Repo
aws ecr create-repository --repository-name lambda-container-demo

## b. Authenticate Docker to ECR
aws ecr get-login-password | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com

## c. Build and Push Image
cd lambda_container
docker build -t lambda-container-demo .
docker tag lambda-container-demo:latest <aws_account_id>.dkr.ecr.<region>.amazonaws.com/lambda-container-demo:latest
docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/lambda-container-demo:latest

## Deploy with Terraform

terraform init
terraform plan
terraform apply

## Confirm when prompted.

# Test the Lambda Function
Get the API Gateway URL from the output and test it:
curl https://<api-id>.execute-api.<region>.amazonaws.com/

## Expected Output 
"Hello from Lambda container!"

##Clean up 
terraform destroy

##Directory Structure 
terraform-serverless-container/
├── main.tf
├── variables.tf
├── outputs.tf
├── lambda_container/
│ ├── Dockerfile
│ └── app.py
