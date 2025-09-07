#!/bin/bash

# Coolify Installation Script for OCI ARM64
# This script installs Coolify on Oracle Cloud Infrastructure ARM64 instances
# Based on Coolify documentation and KASM deployment patterns

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "❌ Error: .env file not found. Please copy .env.example to .env and configure it."
    exit 1
fi

# Required environment variables
REQUIRED_VARS=(
    "COOLIFY_SERVER_IP"
    "SSH_USER" 
    "SSH_KEY_PATH"
    "COOLIFY_PORT"
    "ROOT_USERNAME"
    "ROOT_USER_EMAIL"
    "ROOT_USER_PASSWORD"
)

echo "🚀 Coolify Installation Script for OCI ARM64"
echo "📋 Instance: $COOLIFY_SERVER_IP"
echo "🔑 SSH Key: $SSH_KEY_PATH"
echo "👤 SSH User: $SSH_USER"
echo "🏗️  Architecture: ARM64 (Ampere)"
echo "🌐 Coolify Port: $COOLIFY_PORT"
echo ""

# Validate required environment variables
echo "📋 Validating environment configuration..."
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Missing required environment variable: $var"
        exit 1
    fi
    echo "✅ $var: ${!var}"
done
echo ""

# Function to run SSH commands with proper error handling
run_ssh_command() {
    local command="$1"
    local description="$2"
    
    echo "🔧 $description"
    echo "📝 Executing on remote instance..."
    
    if ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=30 "$SSH_USER@$COOLIFY_SERVER_IP" "$command"; then
        echo "✅ $description completed successfully"
        echo ""
        return 0
    else
        echo "❌ $description failed"
        echo ""
        return 1
    fi
}

# Function to upload files via SCP
upload_file() {
    local local_file="$1"
    local remote_file="$2"
    local description="$3"
    
    echo "📤 $description"
    echo "📁 Local: $local_file"
    echo "📁 Remote: $remote_file"
    
    if scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$local_file" "$SSH_USER@$COOLIFY_SERVER_IP:$remote_file"; then
        echo "✅ $description completed successfully"
        echo ""
        return 0
    else
        echo "❌ $description failed"
        echo ""
        return 1
    fi
}

# Step 1: System verification and updates
echo "🔍 Step 1: System verification and updates..."
SYSTEM_CHECK_CMD='#!/bin/bash
set -e
echo "Checking system information..."
echo "OS: $(lsb_release -d | cut -f2)"
echo "Architecture: $(uname -m)"
echo "Kernel: $(uname -r)"
echo "Memory: $(free -h | grep Mem | awk "{print \$2}")"
echo "Storage: $(df -h / | tail -1 | awk "{print \$2\" total, \"\$4\" available\"}")"
echo ""
echo "Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y
echo "System update completed"'

if ! run_ssh_command "$SYSTEM_CHECK_CMD" "System verification and updates"; then
    exit 1
fi

# Step 2: Install Docker (required for Coolify)
echo "🐳 Step 2: Installing Docker..."
DOCKER_INSTALL_CMD='#!/bin/bash
set -e
echo "Installing Docker dependencies..."
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

echo "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Installing Docker..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "Starting and enabling Docker..."
sudo systemctl start docker
sudo systemctl enable docker

echo "Adding user to docker group..."
sudo usermod -aG docker $USER

echo "Verifying Docker installation..."
sudo docker --version
sudo docker compose version

echo "Docker installation completed"'

if ! run_ssh_command "$DOCKER_INSTALL_CMD" "Installing Docker"; then
    exit 1
fi

# Step 3: Install additional dependencies
echo "📦 Step 3: Installing additional dependencies..."
DEPS_INSTALL_CMD='#!/bin/bash
set -e
echo "Installing additional dependencies for Coolify..."
sudo apt-get install -y curl wget git unzip jq openssh-server

echo "Ensuring SSH server is running..."
sudo systemctl enable --now ssh

echo "Installing latest curl (if needed)..."
sudo apt-get install -y curl

echo "Dependencies installation completed"'

if ! run_ssh_command "$DEPS_INSTALL_CMD" "Installing additional dependencies"; then
    exit 1
fi

# Step 4: Download and install Coolify
echo "🚀 Step 4: Installing Coolify..."
COOLIFY_INSTALL_CMD='#!/bin/bash
set -e
echo "Installing Coolify using automated installation script..."

# Set environment variables for automated setup
export ROOT_USERNAME="'"$ROOT_USERNAME"'"
export ROOT_USER_EMAIL="'"$ROOT_USER_EMAIL"'"
export ROOT_USER_PASSWORD="'"$ROOT_USER_PASSWORD"'"

# Install Coolify with environment variables
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

echo "Coolify installation completed"
echo "Waiting for services to start..."
sleep 30'

if ! run_ssh_command "$COOLIFY_INSTALL_CMD" "Installing Coolify"; then
    exit 1
fi

# Step 5: Verify Coolify services
echo "✅ Step 5: Verifying Coolify services..."
VERIFY_SERVICES_CMD='#!/bin/bash
set -e
echo "Checking Coolify containers..."
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep coolify || echo "No coolify containers found yet"

echo ""
echo "Checking Docker network..."
sudo docker network ls | grep coolify || echo "Coolify network not found"

echo ""
echo "Checking service health..."
CONTAINER_COUNT=$(sudo docker ps | grep coolify | wc -l || echo "0")
echo "Running Coolify containers: $CONTAINER_COUNT"

echo ""
echo "Testing local Coolify access..."
sleep 10
if curl -k -s --connect-timeout 10 http://localhost:8000 > /dev/null; then
    echo "✅ Coolify web interface is accessible locally"
elif curl -k -s --connect-timeout 10 http://localhost:8000/api/health > /dev/null; then
    echo "✅ Coolify API health endpoint is accessible"
else
    echo "⚠️  Coolify web interface may still be starting up"
    echo "Checking if Coolify is still initializing..."
    sudo docker logs coolify 2>/dev/null | tail -10 || echo "Coolify container logs not available yet"
fi

echo ""
echo "Checking Coolify service ports..."
sudo netstat -tlnp | grep -E ":(8000|6001|6002)" || echo "Port check completed"'

if ! run_ssh_command "$VERIFY_SERVICES_CMD" "Verifying Coolify services"; then
    echo "⚠️  Service verification had issues, but continuing..."
fi

# Step 6: Configure firewall and security
echo "🔒 Step 6: Configuring firewall and security..."
SECURITY_CONFIG_CMD='#!/bin/bash
set -e
echo "Configuring UFW firewall..."
sudo ufw --force enable

echo "Allowing SSH access..."
sudo ufw allow 22/tcp

echo "Allowing Coolify web interface..."
sudo ufw allow 8000/tcp

echo "Allowing HTTP/HTTPS for proxy..."
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

echo "Allowing Coolify proxy ports..."
sudo ufw allow 6001/tcp
sudo ufw allow 6002/tcp

echo "Checking firewall status..."
sudo ufw status

echo "Firewall configuration completed"'

if ! run_ssh_command "$SECURITY_CONFIG_CMD" "Configuring firewall and security"; then
    exit 1
fi

# Step 7: Get Coolify access information
echo "🔑 Step 7: Retrieving Coolify access information..."
CREDENTIALS_CMD='#!/bin/bash
set -e
echo "Coolify Access Information:"
echo "=========================="

INSTALL_DATE=$(date "+%Y-%m-%d %H:%M:%S UTC")

echo "Installation completed: $INSTALL_DATE"
echo "Instance IP: '"$COOLIFY_SERVER_IP"'"
echo "Coolify URL: http://'"$COOLIFY_SERVER_IP"':8000"
echo ""
echo "Admin Login Information:"
echo "Username: '"$ROOT_USERNAME"'"
echo "Email: '"$ROOT_USER_EMAIL"'"
echo "Password: '"$ROOT_USER_PASSWORD"'"
echo ""

# Save access information to file
cat > ~/coolify-access.txt << EOF
# Coolify Access Information
# Generated: $INSTALL_DATE
# Instance: '"$COOLIFY_SERVER_IP"'

## Admin Login Information
Username: '"$ROOT_USERNAME"'"
Email: '"$ROOT_USER_EMAIL"'"
Password: '"$ROOT_USER_PASSWORD"'"

## Access URLs
Web Interface: http://'"$COOLIFY_SERVER_IP"':8000
Tunnel URL: https://'"${TUNNEL_HOSTNAME:-coolify.hdvfx.com}"'

## Important Notes
- Access Coolify at http://'"$COOLIFY_SERVER_IP"':8000
- Complete initial setup in the web interface
- Configure your first server (localhost)
- Set up your first project and application
- Default proxy is Traefik (recommended)

## Service Management Commands
Check containers: sudo docker ps | grep coolify
View logs: sudo docker logs coolify
Restart Coolify: sudo docker restart coolify
Update Coolify: curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash

## Firewall Ports
- 8000: Coolify Web Interface (HTTP)
- 80: HTTP Proxy
- 443: HTTPS Proxy  
- 6001: Proxy HTTP
- 6002: Proxy HTTPS

## Next Steps
1. Access the web interface
2. Complete the initial setup wizard
3. Add your first server (localhost)
4. Deploy your first application
5. Set up Cloudflare tunnel (optional)

Generated by Coolify Installation Script
EOF

echo "✅ Access information saved to ~/coolify-access.txt"'

if ! run_ssh_command "$CREDENTIALS_CMD" "Retrieving Coolify access information"; then
    exit 1
fi

# Download access information file to local machine
echo "📥 Downloading access information file to local machine..."
if scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$SSH_USER@$COOLIFY_SERVER_IP:~/coolify-access.txt" "$SCRIPT_DIR/coolify-access.txt"; then
    echo "✅ Access information downloaded to: $SCRIPT_DIR/coolify-access.txt"
    echo ""
    echo "📋 Coolify Access Information (also saved to coolify-access.txt):"
    echo "================================================================"
    cat "$SCRIPT_DIR/coolify-access.txt"
    echo ""
else
    echo "⚠️  Could not download access file, but it's saved on the server at ~/coolify-access.txt"
fi

# Step 8: Final verification and testing
echo "🔍 Step 8: Final verification and testing..."
FINAL_TEST_CMD='#!/bin/bash
set -e
echo "Final Coolify verification..."
echo "============================="

echo "1. Container status:"
sudo docker ps --format "table {{.Names}}\t{{.Status}}" | grep coolify || echo "No coolify containers running"

echo ""
echo "2. Service ports:"
sudo netstat -tlnp | grep -E ":(8000|6001|6002)" | head -5 || echo "No services listening on expected ports"

echo ""
echo "3. System resources:"
echo "Memory usage: $(free -h | grep Mem | awk "{print \$3\"/\"\$2}")"
echo "Disk usage: $(df -h / | tail -1 | awk "{print \$3\"/\"\$2\" (\"\$5\" used)\"}")"

echo ""
echo "4. Web interface test:"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 || echo "000")
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Coolify web interface responding (HTTP $HTTP_STATUS)"
elif [ "$HTTP_STATUS" = "302" ] || [ "$HTTP_STATUS" = "301" ]; then
    echo "✅ Coolify web interface responding with redirect (HTTP $HTTP_STATUS)"
else
    echo "⚠️  Coolify web interface status: HTTP $HTTP_STATUS"
    echo "This may be normal if Coolify is still initializing"
fi

echo ""
echo "5. Docker network check:"
sudo docker network ls | grep coolify && echo "✅ Coolify network exists" || echo "⚠️  Coolify network not found"

echo ""
echo "🎉 Coolify installation completed!"
echo ""
echo "Access your Coolify instance at:"
echo "  🌐 http://'"$COOLIFY_SERVER_IP"':8000"
echo ""
echo "Next steps:"
echo "  1. Open the web interface in your browser"
echo "  2. Complete the initial setup wizard"
echo "  3. Add localhost as your first server"
echo "  4. Create your first project"
echo "  5. Deploy your first application"'

if ! run_ssh_command "$FINAL_TEST_CMD" "Final verification and testing"; then
    echo "⚠️  Final verification had some issues, but installation may still be successful"
fi

echo ""
echo "🎉 Coolify Installation Completed!"
echo ""
echo "📋 Installation Summary:"
echo "   Instance: $COOLIFY_SERVER_IP"
echo "   Web Interface: http://$COOLIFY_SERVER_IP:$COOLIFY_PORT"
echo "   Architecture: ARM64 (Ampere)"
echo "   Access File: $SCRIPT_DIR/coolify-access.txt"
echo ""
echo "🔧 Management Commands:"
echo "   Check status: ssh -i $SSH_KEY_PATH $SSH_USER@$COOLIFY_SERVER_IP 'sudo docker ps | grep coolify'"
echo "   View logs: ssh -i $SSH_KEY_PATH $SSH_USER@$COOLIFY_SERVER_IP 'sudo docker logs coolify'"
echo "   Restart Coolify: ssh -i $SSH_KEY_PATH $SSH_USER@$COOLIFY_SERVER_IP 'sudo docker restart coolify'"
echo ""
echo "🔑 Admin Access:"
echo "   Username: $ROOT_USERNAME"
echo "   Email: $ROOT_USER_EMAIL"
echo "   Password: See coolify-access.txt file"
echo ""
echo "🌐 Access URL:"
echo "   http://$COOLIFY_SERVER_IP:$COOLIFY_PORT"
echo ""
echo "✅ Ready for Cloudflare tunnel setup (run coolify-cloudflare-tunnel-setup.sh)"
echo "✅ Ready to start deploying applications!"