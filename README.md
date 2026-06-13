# Threads App — Full-Stack DevOps Project


A production-ready deployment of a **Meta Threads-inspired web application** built with Next.js and MongoDB, fully DevOpsified with Docker, Jenkins CI/CD, Kubernetes on AWS EKS, Terraform IaC, and Ansible automation.


---


## Tech Stack


### Application
| Layer | Technology |
|-------|------------|
| Frontend / Backend | Next.js |
| Database | MongoDB |


### DevOps
| Tool | Purpose |
|------|---------|
| Docker | Containerize the application |
| Jenkins | CI/CD pipeline |
| Kubernetes (EKS) | Container orchestration |
| Terraform | Infrastructure as Code |
| Ansible | Configuration management & automation |
| AWS ECR | Private container registry |
| AWS CloudWatch | Monitoring & logging |


---


## 📁 Project Structure


<pre>
├── application/
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
├── jenkins/
│   └── Jenkinsfile
├── kubernetes/
├── terraform/
│   ├── modules/
│   │   ├── jenkins/
│   │   ├── ecr/
│   │   ├── eks/
│   │   └── jenkins-monitoring/
│   └── main.tf
|   └── s3-backend
└── ansible/
    ├── jenkins-setup.yaml
    ├── install-tools.yaml
    ├── jenkins-cred-creation.yaml
    └── install-cloudwatch-agent.yaml
</pre>
---

## Docker Image Optimization
~83% reduction in content size and ~80% reduction in disk usage achieved with multi-stage build.

| Build Type | Content Size | Disk Usage |
|------------|-------------|------------|
| Single-Stage Build | 336 MB | 1.27 GB |
| Multi-Stage Build | 57.8 MB | 251 MB |


## Terraform Modules


### 1. `jenkins-ec2`
Provisions the Jenkins server on AWS EC2.
- IAM instance profile for CloudWatch agent
- VPC, Subnet, Internet Gateway
- Route table & association
- EC2 instance


### 2. `ecr`
- Private ECR repository for storing Docker images


### 3. `eks`
Provisions the Kubernetes cluster using the official EKS Terraform module.
- VPC for EKS
- EKS cluster with managed node groups
- Service account with IAM role (IRSA)
- AWS Load Balancer Controller


### 4. `jenkins-monitoring`
Full observability setup for the Jenkins EC2 instance.
- CloudWatch alarms
- CloudWatch agent configuration
- CloudWatch dashboard  
- Log groups & log streams
- SNS topic for alert notifications


### 5. `s3-backend`
Remote Terraform state management.
- S3 bucket for storing `.tfstate` files
- DynamoDB table for state locking


---


## CI/CD Pipeline


Jenkins is used as the CI/CD tool. The pipeline automates the following stages:


```text
Code Commit → Build → Test → Docker Build → Push to Amazon ECR → Deploy to Amazon EKS
```


---


## Ansible Automation


Ansible playbooks for automated server and tool configuration.


| Playbook | Purpose |
|----------|---------|
| `jenkins-setup.yaml` | Installs Docker & Docker Compose, starts the Jenkins container |
| `install-tools.yaml` | Installs AWS CLI, kubectl and Node.js inside the Jenkins container |
| `jenkins-cred-creation.yaml` | To create jenkins credentials |
| `install-cloudwatch-agent.yaml` | Installs & starts the CloudWatch agent; sets up a custom metrics cron job to push metrics to CloudWatch |


---
## Monitoring & Observability


Jenkins infrastructure monitoring is managed via the `jenkins-monitoring` Terraform module using AWS CloudWatch.


- **Alarms** - CPU, memory, and disk threshold alerts
- **Dashboard** - Centralized CloudWatch dashboard for Jenkins metrics
- **Logs** - Application and system logs streamed to CloudWatch Log Groups
- **Custom Metrics** - Pushed via a scheduled job installed by Ansible
- **SNS Notifications** - Alerts delivered via SNS topics and subscriptions


---
## Getting Started

Follow the steps below to deploy the application from scratch.

### Prerequisites

Before starting, make sure you have:

- AWS account with required permissions
- Terraform installed
- Ansible installed
- MongoDB database
- GitHub repository access
- Clerk account and application configured
- Gmail account with App Password enabled

### 1. Configure Application Secrets

#### MongoDB

Create a MongoDB database and obtain the connection string:

```env
MONGODB_URL=<mongodb-connection-string>
```

#### Clerk

Get the following credentials from the Clerk dashboard:

```env
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=<value>
CLERK_SECRET_KEY=<value>
NEXT_CLERK_WEBHOOK_SECRET=<value>
```

### 2. Create Terraform Backend

Create the remote backend for storing Terraform state files.

```bash
cd terraform/s3-backend

terraform init
terraform plan
terraform apply
```

### 3. Provision Infrastructure

Create the required AWS infrastructure:

- Jenkins EC2 instance
- Amazon ECR repository
- Amazon EKS cluster
- CloudWatch monitoring resources

```bash
cd terraform

terraform init
terraform plan
terraform apply
```

### 4. Setup Jenkins

#### Update Ansible Inventory

Update the Jenkins EC2 public IP in:

```text
ansible/hosts
```

#### Install Jenkins

```bash
ansible-playbook jenkins-setup.yaml
```

#### Install Required Tools

```bash
ansible-playbook install-tools.yaml
```

This installs:

- AWS CLI
- kubectl
- Node.js

inside the Jenkins container.

### 5. Configure Jenkins

#### Access Jenkins

Open:

```text
http://<jenkins-public-ip>:8080
```

Retrieve the initial admin password:

```bash
/var/lib/jenkins/secrets/initialAdminPassword
```

Then:

- Install suggested plugins
- Create the admin user

#### Create Credentials

Configure:

- GitHub credentials
- AWS credentials
- Gmail credentials
- Application environment variables

Update values in:

```text
ansible/jenkins-credentials.yaml
```

Apply credentials:

```bash
ansible-playbook jenkins-cred-creation.yaml
```

### 6. Create Jenkins Pipeline

Create a new **Pipeline** job and configure:

| Setting | Value |
|----------|--------|
| Repository URL | https://github.com/Mitesh12ehd/threads-app-deployment.git |
| Branch | */main |
| Script Path | jenkins/Jenkinsfile |

### 7. Configure GitHub Webhook

In Jenkins:

- Enable **GitHub hook trigger for GITScm polling**
- Save the pipeline

In GitHub Repository:

1. Settings
2. Webhooks
3. Add Webhook

Configuration:

```text
Payload URL:
http://<jenkins-public-ip>:8080/github-webhook/

Content Type:
application/json

SSL Verification:
Disable

Events:
Just the push event
```

After creation, verify webhook delivery returns:

```text
Response: 200
```

### 8. Configure Email Notifications

Navigate to:

```text
Manage Jenkins → System
```

#### Extended E-mail Notification

```text
SMTP Server: smtp.gmail.com
SMTP Port: 587
Use TLS: Enabled
Content Type: HTML
```

Select the Gmail credentials created earlier.

#### E-mail Notification

```text
SMTP Server: smtp.gmail.com
Use SMTP Authentication: Enabled
Username: Gmail Address
Password: Gmail App Password
Use TLS: Enabled
```

Save the configuration and send a test email.

### 9. Deploy the Application

Run the pipeline once manually to perform the initial deployment.

### 10. Configure CloudWatch Agent

Install the CloudWatch agent and custom metrics jobs:

```bash
cd ansible

ansible-playbook install-cloudwatch-agent.yaml
```