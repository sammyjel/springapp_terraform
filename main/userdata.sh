#!/bin/bash

# Set working directory
cd

# Install necessary packages
sudo yum update -y
sudo yum install docker containerd git screen jq -y

# Setup Docker Compose
wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)
sudo mv docker-compose-$(uname -s)-$(uname -m) /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose

# Start Docker
systemctl enable docker.service --now
sudo usermod -a -G docker ssm-user
sudo usermod -a -G docker ec2-user
systemctl restart docker.service

# Fetch RDS password from Secrets Manager (assuming only password is stored)
SECRET_NAME="${project_name}-db-password"
REGION="${region}"

# Fetch the secret value using AWS CLI
MYSQL_PASSWORD=$(aws secretsmanager get-secret-value --secret-id $SECRET_NAME --region $REGION --query SecretString --output text)

# Define other required variables (passed from Terraform or manually defined)
MYSQL_USER="admin"  # Replace with actual username
MYSQL_URL="${mysql_url}"  # Pass this value via Terraform
MYSQL_ROOT_PASSWORD="root"
MYSQL_DATABASE="petclinic"

# Run the Docker container using the secrets
docker pull karthik0741/images:petclinic_img
docker run -e MYSQL_URL=jdbc:mysql://$MYSQL_URL/$MYSQL_DATABASE \
           -e MYSQL_USER=$MYSQL_USER \
           -e MYSQL_PASSWORD=$MYSQL_PASSWORD \
           -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
           -e MYSQL_DATABASE=$MYSQL_DATABASE \
           -p 80:8080 docker.io/karthik0741/images:petclinic_img
