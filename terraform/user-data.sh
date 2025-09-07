#!/bin/bash
# User data script for Semaphore instance
# Workspace: ${workspace}

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install git
yum install -y git

# Create semaphore user
useradd -m -s /bin/bash semaphore
usermod -aG docker semaphore

# Log the deployment
echo "Semaphore instance deployed for workspace: ${workspace}" >> /var/log/deployment.log
echo "Deployment time: $(date)" >> /var/log/deployment.log

# Note: Actual Semaphore deployment would be added here
# This is just a basic setup for the infrastructure