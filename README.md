# 🧵 Threads App — Full-Stack DevOps Project

A production-ready deployment of a **Meta Threads-inspired web application** built with Next.js and MongoDB, fully DevOpsified with Docker, Jenkins CI/CD, Kubernetes on AWS EKS, Terraform IaC, and Ansible automation.

---

## 📋 Table of Contents

- [Application Overview](#application-overview)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Infrastructure Overview](#infrastructure-overview)
- [Terraform Modules](#terraform-modules)
- [CI/CD Pipeline](#cicd-pipeline)
- [Ansible Automation](#ansible-automation)
- [Monitoring & Observability](#monitoring--observability)
- [Getting Started](#getting-started)

---

## 🖥️ Application Overview

A full-stack social threading application inspired by Meta Threads. Users can create threads, reply, follow others, and engage in conversations — containerized and deployed on a scalable Kubernetes cluster on AWS.

---

## 🛠️ Tech Stack

### Application
| Layer | Technology |
|-------|------------|
| Frontend / Backend | Next.js |
| Database | MongoDB |
| Containerization | Docker & Docker Compose |

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
├── app/                        # Next.js application source
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
├── jenkins/
│   └── Jenkinsfile
├── k8s/                        # Kubernetes manifests
├── terraform/
│   ├── modules/
│   │   ├── jenkins-ec2/
│   │   ├── ecr/
│   │   ├── eks/
│   │   ├── jenkins-monitoring/
│   │   └── s3-backend/
│   └── main.tf
└── ansible/
    ├── install-docker-jenkins.yml
    ├── install-tools.yml
    ├── configure-jenkins-credentials.yml
    └── setup-cloudwatch.yml
</pre>

---

## ☁️ Infrastructure Overview

All infrastructure is provisioned on **AWS** using Terraform and follows a modular approach.

<pre>
┌─────────────────────────────────────────┐
│                AWS Cloud                │
│                                         │
│   ┌───────────┐       ┌───────────┐     │
│   │  Jenkins  │       │  AWS ECR  │     │
│   │    EC2    ├──────►│ (Registry)│     │
│   └─────┬─────┘       └─────┬─────┘     │
│         │                   │           │
│         ▼                   ▼           │
│   ┌───────────────────────────┐         │
│   │      AWS EKS Cluster      │         │
│   │                           │         │
│   │  ┌─────────┐   ┌─────────┐│         │
│   │  │  Node   │   │  Node   ││         │
│   │  │  Group  │   │  Group  ││         │
│   │  └─────────┘   └─────────┘│         │
│   └───────────────────────────┘         │
│                                         │
│   ┌───────────┐       ┌───────────┐     │
│   │    S3     │       │ DynamoDB  │     │
│   │ (TF State)│       │ (Locking) │     │
│   └───────────┘       └───────────┘     │
└─────────────────────────────────────────┘
</pre>
---

## 🏗️ Terraform Modules

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

## 🔄 CI/CD Pipeline

Jenkins is used as the CI/CD engine. The pipeline automates the following stages:


<pre>
       Code Push
           │
           ▼
┌───────────┐     ┌───────────┐     ┌───────────────┐     ┌───────────┐
│   Build   ├────►│   Test    ├────►│ Docker Build  ├────►│  Push to  │
│  Next.js  │     │           │     │    & Tag      │     │    ECR    │
└───────────┘     └───────────┘     └───────────────┘     └─────┬─────┘
                                                                │
                                                                ▼
                                                          ┌───────────┐
                                                          │ Deploy to │
                                                          │EKS Cluster│
                                                          └───────────┘
</pre>

---

## ⚙️ Ansible Automation

Ansible playbooks are triggered through Jenkins for automated server and tool configuration.

| Playbook | Purpose |
|----------|---------|
| `install-docker-jenkins.yml` | Installs Docker & Docker Compose, starts the Jenkins container |
| `install-tools.yml` | Installs AWS CLI and Node.js inside the Jenkins container |
| `configure-jenkins-credentials.yml` | Programmatically creates credentials in Jenkins |
| `setup-cloudwatch.yml` | Installs & starts the CloudWatch agent; sets up a custom metrics cron job to push metrics to CloudWatch |

---

## 📊 Monitoring & Observability

Jenkins infrastructure monitoring is managed via the `jenkins-monitoring` Terraform module using AWS CloudWatch.

- **Alarms** — CPU, memory, and disk threshold alerts
- **Dashboard** — Centralized CloudWatch dashboard for Jenkins metrics
- **Logs** — Application and system logs streamed to CloudWatch Log Groups
- **Custom Metrics** — Pushed via a scheduled job installed by Ansible
- **SNS Notifications** — Alerts delivered via SNS topics

---

## 🚀 Getting Started

### Prerequisites
- AWS CLI configured
- Terraform >= 1.x
- kubectl
- Ansible
- Docker

### 1. Provision Remote Backend
```bash
cd terraform/modules/s3-backend
terraform init && terraform apply
```

### 2. Provision Jenkins EC2
```bash
cd terraform/modules/jenkins-ec2
terraform init && terraform apply
```

### 3. Run Ansible Playbooks
```bash
# Install Docker & start Jenkins
ansible-playbook ansible/install-docker-jenkins.yml

# Install tools inside Jenkins container
ansible-playbook ansible/install-tools.yml

# Configure Jenkins credentials
ansible-playbook ansible/configure-jenkins-credentials.yml

# Setup CloudWatch agent & custom metrics
ansible-playbook ansible/setup-cloudwatch.yml
```

### 4. Provision ECR & EKS
```bash
cd terraform/modules/ecr && terraform apply
cd terraform/modules/eks && terraform apply
```

### 5. Trigger Jenkins Pipeline
Push to the main branch or trigger the Jenkins pipeline manually to build, push the Docker image to ECR, and deploy to EKS.

---
