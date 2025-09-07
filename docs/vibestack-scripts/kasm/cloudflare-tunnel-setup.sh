#!/bin/bash

# Cloudflare Tunnel Setup Script
# This script consolidates all the essential commands from the Cloudflare tunnel setup process

set -e

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "❌ .env file not found in $SCRIPT_DIR"
    exit 1
fi

echo "🚀 Cloudflare Tunnel Setup for KASM Workspaces"
echo "=============================================="
echo ""

# Validate required environment variables
required_vars=(
    "CLOUDFLARE_API_TOKEN"
    "CLOUDFLARE_ACCOUNT_ID"
    "TUNNEL_NAME"
    "TUNNEL_HOSTNAME"
    "KASM_SERVER_IP"
    "KASM_PORT"
    "SSH_USER"
    "SSH_KEY_PATH"
)

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Required environment variable $var is not set"
        exit 1
    fi
done

echo "📋 Configuration:"
echo "   Tunnel Name: $TUNNEL_NAME"
echo "   Hostname: $TUNNEL_HOSTNAME"
echo "   KASM Server: $KASM_SERVER_IP:$KASM_PORT"
echo "   Account ID: $CLOUDFLARE_ACCOUNT_ID"
echo ""

# Step 1: Create Cloudflare Tunnel
echo "🔧 Step 1: Creating Cloudflare Tunnel..."
TUNNEL_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/cfd_tunnel" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"name\":\"$TUNNEL_NAME\",\"config_src\":\"cloudflare\"}")

# Extract tunnel ID from response
TUNNEL_ID=$(echo "$TUNNEL_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$TUNNEL_ID" ]; then
    echo "❌ Failed to create tunnel or tunnel already exists"
    echo "Response: $TUNNEL_RESPONSE"
    # Try to get existing tunnel
    echo "🔍 Checking for existing tunnel..."
    EXISTING_TUNNEL=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/cfd_tunnel?name=$TUNNEL_NAME" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")
    TUNNEL_ID=$(echo "$EXISTING_TUNNEL" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [ -z "$TUNNEL_ID" ]; then
        echo "❌ Could not create or find tunnel"
        exit 1
    else
        echo "✅ Using existing tunnel: $TUNNEL_ID"
    fi
else
    echo "✅ Tunnel created successfully: $TUNNEL_ID"
fi

# Update .env file with tunnel ID
if ! grep -q "TUNNEL_ID=" "$SCRIPT_DIR/.env"; then
    echo "TUNNEL_ID=$TUNNEL_ID" >> "$SCRIPT_DIR/.env"
else
    sed -i "s/TUNNEL_ID=.*/TUNNEL_ID=$TUNNEL_ID/" "$SCRIPT_DIR/.env"
fi

echo ""

# Step 2: Get Zone ID (if not provided)
if [ -z "$CLOUDFLARE_ZONE_ID" ]; then
    echo "🔍 Step 2: Getting Zone ID for domain..."
    ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$TUNNEL_DOMAIN" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" | \
      grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [ -z "$ZONE_ID" ]; then
        echo "❌ Failed to get zone ID for domain: $TUNNEL_DOMAIN"
        exit 1
    fi
    
    echo "✅ Zone ID: $ZONE_ID"
    
    # Update .env file with zone ID
    if ! grep -q "CLOUDFLARE_ZONE_ID=" "$SCRIPT_DIR/.env"; then
        echo "CLOUDFLARE_ZONE_ID=$ZONE_ID" >> "$SCRIPT_DIR/.env"
    else
        sed -i "s/CLOUDFLARE_ZONE_ID=.*/CLOUDFLARE_ZONE_ID=$ZONE_ID/" "$SCRIPT_DIR/.env"
    fi
else
    ZONE_ID="$CLOUDFLARE_ZONE_ID"
    echo "✅ Using provided Zone ID: $ZONE_ID"
fi

echo ""

# Step 3: Create DNS CNAME Record
echo "🌐 Step 3: Creating DNS CNAME record..."
HOSTNAME_PART=$(echo "$TUNNEL_HOSTNAME" | cut -d'.' -f1)
TUNNEL_DOMAIN_TARGET="$TUNNEL_ID.cfargotunnel.com"

DNS_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"CNAME\",\"name\":\"$HOSTNAME_PART\",\"content\":\"$TUNNEL_DOMAIN_TARGET\",\"proxied\":true,\"comment\":\"Cloudflare Tunnel for KASM Workspaces\"}")

DNS_SUCCESS=$(echo "$DNS_RESPONSE" | grep -o '"success":[^,]*' | cut -d':' -f2)

if [ "$DNS_SUCCESS" = "true" ]; then
    echo "✅ DNS CNAME record created: $TUNNEL_HOSTNAME -> $TUNNEL_DOMAIN_TARGET"
    
    # Extract and save DNS record ID
    DNS_RECORD_ID=$(echo "$DNS_RESPONSE" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ -n "$DNS_RECORD_ID" ]; then
        if ! grep -q "DNS_RECORD_ID=" "$SCRIPT_DIR/.env"; then
            echo "DNS_RECORD_ID=$DNS_RECORD_ID" >> "$SCRIPT_DIR/.env"
        else
            sed -i "s/DNS_RECORD_ID=.*/DNS_RECORD_ID=$DNS_RECORD_ID/" "$SCRIPT_DIR/.env"
        fi
    fi
else
    echo "⚠️  DNS record creation failed or already exists"
    echo "Response: $DNS_RESPONSE"
    
    # Try to find existing record
    echo "🔍 Checking for existing DNS record..."
    EXISTING_DNS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$TUNNEL_HOSTNAME" \
      -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")
    
    EXISTING_RECORD_ID=$(echo "$EXISTING_DNS" | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
    if [ -n "$EXISTING_RECORD_ID" ]; then
        echo "✅ Found existing DNS record: $EXISTING_RECORD_ID"
        if ! grep -q "DNS_RECORD_ID=" "$SCRIPT_DIR/.env"; then
            echo "DNS_RECORD_ID=$EXISTING_RECORD_ID" >> "$SCRIPT_DIR/.env"
        else
            sed -i "s/DNS_RECORD_ID=.*/DNS_RECORD_ID=$EXISTING_RECORD_ID/" "$SCRIPT_DIR/.env"
        fi
    fi
fi

echo ""

# Step 4: Configure Tunnel Ingress Rules
echo "⚙️  Step 4: Configuring tunnel ingress rules..."
INGRESS_CONFIG=$(cat <<EOF
{
  "config": {
    "ingress": [
      {
        "hostname": "$TUNNEL_HOSTNAME",
        "service": "https://$KASM_SERVER_IP:$KASM_PORT",
        "originRequest": {
          "noTLSVerify": true,
          "connectTimeout": 30000000000,
          "tlsTimeout": 30000000000,
          "tcpKeepAlive": 30000000000,
          "keepAliveConnections": 10,
          "keepAliveTimeout": 90000000000,
          "httpHostHeader": "$KASM_SERVER_IP:$KASM_PORT"
        }
      },
      {
        "service": "http_status:404"
      }
    ]
  }
}
EOF
)

INGRESS_RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/cfd_tunnel/$TUNNEL_ID/configurations" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "$INGRESS_CONFIG")

INGRESS_SUCCESS=$(echo "$INGRESS_RESPONSE" | grep -o '"success":[^,]*' | cut -d':' -f2)

if [ "$INGRESS_SUCCESS" = "true" ]; then
    echo "✅ Tunnel ingress rules configured successfully"
else
    echo "❌ Failed to configure tunnel ingress rules"
    echo "Response: $INGRESS_RESPONSE"
    exit 1
fi

echo ""

# Step 5: Get Tunnel Credentials
echo "🔑 Step 5: Retrieving tunnel credentials..."
TUNNEL_CREDS_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$CLOUDFLARE_ACCOUNT_ID/cfd_tunnel/$TUNNEL_ID/token" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN")

TUNNEL_TOKEN=$(echo "$TUNNEL_CREDS_RESPONSE" | grep -o '"result":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TUNNEL_TOKEN" ]; then
    echo "❌ Failed to retrieve tunnel credentials"
    echo "Response: $TUNNEL_CREDS_RESPONSE"
    exit 1
fi

echo "✅ Tunnel credentials retrieved successfully"
echo ""

# Step 6: Generate Configuration Files
echo "📝 Step 6: Generating configuration files..."

# Create config directory
CONFIG_DIR="$SCRIPT_DIR/config"
mkdir -p "$CONFIG_DIR"

# Generate tunnel config.yml for remote server
cat > "$CONFIG_DIR/config.yml" << EOF
tunnel: $TUNNEL_ID
credentials-file: /etc/cloudflared/tunnel-credentials.json

ingress:
  - hostname: $TUNNEL_HOSTNAME
    service: https://$KASM_SERVER_IP:$KASM_PORT
    originRequest:
      noTLSVerify: true
      connectTimeout: 30s
      tlsTimeout: 30s
      tcpKeepAlive: 30s
      keepAliveConnections: 10
      keepAliveTimeout: 90s
      httpHostHeader: $KASM_SERVER_IP:$KASM_PORT
  - service: http_status:404
EOF

# Generate systemd service file
cat > "$CONFIG_DIR/cloudflared-$TUNNEL_NAME.service" << EOF
[Unit]
Description=Cloudflare Tunnel for KASM Workspaces ($TUNNEL_NAME)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloudflared tunnel --config /etc/cloudflared/config.yml run
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Configuration files generated in: $CONFIG_DIR"
echo ""

# Function to run SSH commands with proper error handling
run_ssh_command() {
    local command="$1"
    local description="$2"
    
    echo "🔧 $description"
    echo "📝 Executing on KASM server..."
    
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

# Step 7: Install cloudflared on KASM server
echo "📥 Step 7: Installing cloudflared on KASM server..."
INSTALL_CLOUDFLARED_CMD='#!/bin/bash
set -e
echo "Checking if cloudflared is already installed..."
if command -v cloudflared >/dev/null 2>&1; then
    echo "cloudflared is already installed: $(cloudflared --version)"
else
    echo "Installing cloudflared..."
    # Detect architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
    else
        CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
    fi
    
    echo "Downloading cloudflared for $ARCH..."
    curl -L "$CLOUDFLARED_URL" -o /tmp/cloudflared
    sudo mv /tmp/cloudflared /usr/local/bin/cloudflared
    sudo chmod +x /usr/local/bin/cloudflared
    
    echo "cloudflared installed successfully: $(cloudflared --version)"
fi

echo "Creating cloudflared configuration directory..."
sudo mkdir -p /etc/cloudflared
sudo chown root:root /etc/cloudflared
sudo chmod 755 /etc/cloudflared'

if ! run_ssh_command "$INSTALL_CLOUDFLARED_CMD" "Installing cloudflared"; then
    exit 1
fi

# Step 8: Deploy tunnel configuration
echo "📁 Step 8: Deploying tunnel configuration to KASM server..."

# Copy config file
echo "📤 Uploading tunnel configuration..."
if scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$CONFIG_DIR/config.yml" "$SSH_USER@$KASM_SERVER_IP:/tmp/config.yml"; then
    echo "✅ Configuration file uploaded"
else
    echo "❌ Failed to upload configuration file"
    exit 1
fi

# Copy systemd service file
echo "📤 Uploading systemd service file..."
if scp -i "$SSH_KEY_PATH" -o StrictHostKeyChecking=no "$CONFIG_DIR/cloudflared-$TUNNEL_NAME.service" "$SSH_USER@$KASM_SERVER_IP:/tmp/cloudflared-$TUNNEL_NAME.service"; then
    echo "✅ Service file uploaded"
else
    echo "❌ Failed to upload service file"
    exit 1
fi

# Deploy configuration files
DEPLOY_CONFIG_CMD="#!/bin/bash
set -e
echo \"Moving configuration files to proper locations...\"
sudo mv /tmp/config.yml /etc/cloudflared/config.yml
sudo mv /tmp/cloudflared-$TUNNEL_NAME.service /etc/systemd/system/cloudflared-$TUNNEL_NAME.service

echo \"Setting proper permissions...\"
sudo chown root:root /etc/cloudflared/config.yml
sudo chmod 644 /etc/cloudflared/config.yml
sudo chown root:root /etc/systemd/system/cloudflared-$TUNNEL_NAME.service
sudo chmod 644 /etc/systemd/system/cloudflared-$TUNNEL_NAME.service

echo \"Configuration files deployed successfully\""

if ! run_ssh_command "$DEPLOY_CONFIG_CMD" "Deploying configuration files"; then
    exit 1
fi

# Step 9: Deploy tunnel credentials
echo "🔑 Step 9: Deploying tunnel credentials..."
DEPLOY_CREDS_CMD="#!/bin/bash
set -e
echo \"Creating tunnel credentials file...\"
echo '$TUNNEL_TOKEN' | sudo tee /etc/cloudflared/tunnel-credentials.json > /dev/null
sudo chown root:root /etc/cloudflared/tunnel-credentials.json
sudo chmod 600 /etc/cloudflared/tunnel-credentials.json
echo \"Tunnel credentials deployed successfully\""

if ! run_ssh_command "$DEPLOY_CREDS_CMD" "Deploying tunnel credentials"; then
    exit 1
fi

# Step 10: Start tunnel service
echo "🚀 Step 10: Starting Cloudflare tunnel service..."
START_SERVICE_CMD="#!/bin/bash
set -e
echo \"Reloading systemd daemon...\"
sudo systemctl daemon-reload

echo \"Enabling cloudflared service...\"
sudo systemctl enable cloudflared-$TUNNEL_NAME

echo \"Starting cloudflared service...\"
sudo systemctl start cloudflared-$TUNNEL_NAME

echo \"Checking service status...\"
sleep 5
sudo systemctl status cloudflared-$TUNNEL_NAME --no-pager

echo \"Cloudflare tunnel service started successfully\""

if ! run_ssh_command "$START_SERVICE_CMD" "Starting tunnel service"; then
    exit 1
fi

# Step 11: Verify tunnel connectivity
echo "🧪 Step 11: Verifying tunnel connectivity..."
VERIFY_CMD="#!/bin/bash
set -e
echo \"Checking tunnel service status...\"
if sudo systemctl is-active --quiet cloudflared-$TUNNEL_NAME; then
    echo \"✅ Tunnel service is active and running\"
else
    echo \"❌ Tunnel service is not running\"
    sudo systemctl status cloudflared-$TUNNEL_NAME --no-pager
    exit 1
fi

echo \"Checking tunnel logs...\"
sudo journalctl -u cloudflared-$TUNNEL_NAME --no-pager -n 10

echo \"Testing local KASM connectivity...\"
if curl -k -s --connect-timeout 10 https://localhost:$KASM_PORT > /dev/null; then
    echo \"✅ KASM server is accessible locally\"
else
    echo \"❌ KASM server is not accessible locally\"
    exit 1
fi"

if ! run_ssh_command "$VERIFY_CMD" "Verifying tunnel connectivity"; then
    echo "⚠️  Tunnel service started but verification failed. Check logs for details."
fi

echo ""

# Step 12: Final Summary
echo "🎉 Cloudflare Tunnel Setup Complete!"
echo "===================================="
echo ""
echo "📋 Summary:"
echo "   ✅ Tunnel created: $TUNNEL_ID"
echo "   ✅ DNS record configured: $TUNNEL_HOSTNAME"
echo "   ✅ Ingress rules configured"
echo "   ✅ cloudflared installed on KASM server"
echo "   ✅ Tunnel configuration deployed"
echo "   ✅ Tunnel service started and enabled"
echo ""
echo "🌐 Access Information:"
echo "   Public URL: https://$TUNNEL_HOSTNAME"
echo "   Local URL: https://$KASM_SERVER_IP:$KASM_PORT"
echo ""
echo "🔧 Service Management:"
echo "   Check status: ssh -i $SSH_KEY_PATH $SSH_USER@$KASM_SERVER_IP 'sudo systemctl status cloudflared-$TUNNEL_NAME'"
echo "   View logs: ssh -i $SSH_KEY_PATH $SSH_USER@$KASM_SERVER_IP 'sudo journalctl -u cloudflared-$TUNNEL_NAME -f'"
echo "   Restart: ssh -i $SSH_KEY_PATH $SSH_USER@$KASM_SERVER_IP 'sudo systemctl restart cloudflared-$TUNNEL_NAME'"
echo ""
echo "🧪 Test the connection:"
echo "   Wait 2-3 minutes for tunnel to fully establish"
echo "   Then visit: https://$TUNNEL_HOSTNAME"
echo ""
echo "📄 All configuration details saved in: $SCRIPT_DIR/.env"