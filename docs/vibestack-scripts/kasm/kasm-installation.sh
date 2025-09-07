#!/bin/bash

# KASM Workspaces Installation Script for OCI ARM64
# This script installs KASM Workspaces on Oracle Cloud Infrastructure ARM64 instances
# Based on successful deployment thread from KASM Container Admin

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
    "KASM_SERVER_IP"
    "SSH_USER" 
    "SSH_KEY_PATH"
    "KASM_PORT"
    "RDP_PORT"
)

echo "🚀 KASM Workspaces Installation Script for OCI ARM64"
echo "📋 Instance: $KASM_SERVER_IP"
echo "🔑 SSH Key: $SSH_KEY_PATH"
echo "👤 SSH User: $SSH_USER"
echo "🏗️  Architecture: ARM64 (Ampere)"
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
    
    if ssh -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no -o ConnectTimeout=30 "$SSH_USER@$KASM_SERVER_IP" "$command"; then
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
    
    if scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$local_file" "$SSH_USER@$KASM_SERVER_IP:$remote_file"; then
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

# Step 2: Install Docker and dependencies
echo "🐳 Step 2: Installing Docker and dependencies..."
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

if ! run_ssh_command "$DOCKER_INSTALL_CMD" "Installing Docker and dependencies"; then
    exit 1
fi

# Step 3: Download and install KASM Workspaces
echo "📦 Step 3: Downloading and installing KASM Workspaces..."
KASM_INSTALL_CMD='#!/bin/bash
set -e
echo "Creating KASM installation directory..."
mkdir -p ~/kasm-install
cd ~/kasm-install

echo "Downloading KASM Workspaces installer..."
curl -O https://kasm-static-content.s3.amazonaws.com/kasm_release_1.17.0.7f020d.tar.gz

echo "Extracting KASM installer..."
tar -xf kasm_release_1.17.0.7f020d.tar.gz

echo "Running KASM installation..."
cd kasm_release
sudo bash kasm_release/install.sh -v -s

echo "KASM installation completed"
echo "Installation logs available in: ~/kasm-install/kasm_release/"'

if ! run_ssh_command "$KASM_INSTALL_CMD" "Downloading and installing KASM Workspaces"; then
    exit 1
fi

# Step 4: Verify KASM services
echo "✅ Step 4: Verifying KASM services..."
VERIFY_SERVICES_CMD='#!/bin/bash
set -e
echo "Waiting for services to start..."
sleep 30

echo "Checking KASM containers..."
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep kasm

echo ""
echo "Checking service health..."
CONTAINER_COUNT=$(sudo docker ps | grep kasm | wc -l)
echo "Running KASM containers: $CONTAINER_COUNT"

if [ $CONTAINER_COUNT -ge 8 ]; then
    echo "✅ KASM services are running correctly"
else
    echo "⚠️  Warning: Expected at least 8 containers, found $CONTAINER_COUNT"
fi

echo ""
echo "Testing local KASM access..."
if curl -k -s --connect-timeout 10 https://localhost:8443 > /dev/null; then
    echo "✅ KASM web interface is accessible locally"
else
    echo "❌ KASM web interface is not accessible"
    exit 1
fi

echo ""
echo "Checking KASM service ports..."
sudo netstat -tlnp | grep -E ":(8443|3389)" || echo "Port check completed"'

if ! run_ssh_command "$VERIFY_SERVICES_CMD" "Verifying KASM services"; then
    exit 1
fi

# Step 5: Configure firewall and security
echo "🔒 Step 5: Configuring firewall and security..."
SECURITY_CONFIG_CMD='#!/bin/bash
set -e
echo "Configuring UFW firewall..."
sudo ufw --force enable

echo "Allowing SSH access..."
sudo ufw allow 22/tcp

echo "Allowing KASM web interface..."
sudo ufw allow 8443/tcp

echo "Allowing RDP access..."
sudo ufw allow 3389/tcp

echo "Allowing KASM session ports..."
sudo ufw allow 3000:4000/tcp

echo "Checking firewall status..."
sudo ufw status

echo "Firewall configuration completed"'

if ! run_ssh_command "$SECURITY_CONFIG_CMD" "Configuring firewall and security"; then
    exit 1
fi

# Step 6: Get KASM admin credentials and save to file
echo "🔑 Step 6: Retrieving and saving KASM admin credentials..."
CREDENTIALS_CMD='#!/bin/bash
set -e
echo "KASM Admin Credentials:"
echo "========================"
cd ~/kasm-install/kasm_release

# Extract credentials
ADMIN_USERNAME="admin@kasm.local"
ADMIN_PASSWORD=$(sudo grep "admin@kasm.local" install_log.txt | grep -o "Password: [^[:space:]]*" | tail -1 | cut -d" " -f2)
INSTALL_DATE=$(date "+%Y-%m-%d %H:%M:%S UTC")

echo "Default admin username: $ADMIN_USERNAME"
echo "Default admin password: $ADMIN_PASSWORD"
echo ""
echo "Web interface URL: https://'"$KASM_SERVER_IP"':8443"
echo ""

# Save credentials to file
cat > ~/kasm-credentials.txt << EOF
# KASM Workspaces Admin Credentials
# Generated: $INSTALL_DATE
# Instance: '"$KASM_SERVER_IP"'

## Admin Login Information
Username: $ADMIN_USERNAME
Password: $ADMIN_PASSWORD

## Access URLs
Web Interface: https://'"$KASM_SERVER_IP"':8443
Tunnel URL: https://'"${TUNNEL_HOSTNAME:-k2.hdvfx.com}"'

## Important Notes
- Change the default password after first login
- Keep these credentials secure
- Web interface uses self-signed certificates (accept security warning)
- Default session timeout: 30 minutes

## Service Management Commands
Check containers: sudo docker ps | grep kasm
View logs: sudo docker logs kasm_api
Restart services: cd ~/kasm-install/kasm_release && sudo docker compose restart

## Firewall Ports
- 8443: KASM Web Interface (HTTPS)
- 3389: RDP Access
- 3000-4000: Session Ports

Generated by KASM Installation Script
EOF

echo "✅ Credentials saved to ~/kasm-credentials.txt"
echo "Note: Change the default password after first login"'

if ! run_ssh_command "$CREDENTIALS_CMD" "Retrieving and saving KASM admin credentials"; then
    exit 1
fi

# Download credentials file to local machine
echo "📥 Downloading credentials file to local machine..."
if scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$SSH_USER@$KASM_SERVER_IP:~/kasm-credentials.txt" "$SCRIPT_DIR/kasm-credentials.txt"; then
    echo "✅ Credentials file downloaded to: $SCRIPT_DIR/kasm-credentials.txt"
    echo ""
    echo "📋 KASM Admin Credentials (also saved to kasm-credentials.txt):"
    echo "=============================================================="
    cat "$SCRIPT_DIR/kasm-credentials.txt"
    echo ""
else
    echo "⚠️  Could not download credentials file, but it's saved on the server at ~/kasm-credentials.txt"
fi

# Step 7: Final verification and testing
echo "🔍 Step 7: Final verification and testing..."
FINAL_TEST_CMD='#!/bin/bash
set -e
echo "Final KASM verification..."
echo "=========================="

echo "1. Container status:"
sudo docker ps --format "table {{.Names}}\t{{.Status}}" | grep kasm

echo ""
echo "2. Service ports:"
sudo netstat -tlnp | grep -E ":(8443|3389)" | head -5

echo ""
echo "3. System resources:"
echo "Memory usage: $(free -h | grep Mem | awk "{print \$3\"/\"\$2}")"
echo "Disk usage: $(df -h / | tail -1 | awk "{print \$3\"/\"\$2\" (\"\$5\" used)\"}")"

echo ""
echo "4. Web interface test:"
HTTP_STATUS=$(curl -k -s -o /dev/null -w "%{http_code}" https://localhost:8443 || echo "000")
if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ KASM web interface responding (HTTP $HTTP_STATUS)"
else
    echo "⚠️  KASM web interface status: HTTP $HTTP_STATUS"
fi

echo ""
echo "🎉 KASM Workspaces installation completed successfully!"
echo ""
echo "Access your KASM server at:"
echo "  🌐 https://'"$KASM_SERVER_IP"':8443"
echo ""
echo "Next steps:"
echo "  1. Log in with admin credentials"
echo "  2. Change default password"
echo "  3. Configure workspace images"
echo "  4. Set up Cloudflare tunnel (if needed)"'

if ! run_ssh_command "$FINAL_TEST_CMD" "Final verification and testing"; then
    exit 1
fi

echo ""
echo "🎉 KASM Workspaces Installation Completed Successfully!"
echo ""
echo "📋 Installation Summary:"
echo "   Instance: $KASM_SERVER_IP"
echo "   Web Interface: https://$KASM_SERVER_IP:$KASM_PORT"
echo "   RDP Port: $RDP_PORT"
echo "   Architecture: ARM64 (Ampere)"
echo "   Version: KASM Workspaces 1.17.0"
echo "   Credentials File: $SCRIPT_DIR/kasm-credentials.txt"
echo ""
echo "🔧 Management Commands:"
echo "   Check status: ssh -i $SSH_KEY_PATH $SSH_USER@$KASM_SERVER_IP 'sudo docker ps | grep kasm'"
echo "   View logs: ssh -i $SSH_KEY_PATH $SSH_USER@$KASM_SERVER_IP 'sudo docker logs kasm_api'"
echo "   Restart services: ssh -i $SSH_KEY_PATH $SSH_USER@$KASM_SERVER_IP 'cd ~/kasm-install/kasm_release && sudo docker compose restart'"
echo ""
echo "🔑 Admin Access:"
echo "   Username: admin@kasm.local"
echo "   Password: See kasm-credentials.txt file"
echo "   ⚠️  IMPORTANT: Change the default password after first login!"
echo ""
echo "✅ Ready for Cloudflare tunnel setup (run cloudflare-tunnel-setup.sh)"
