#!/bin/bash

# Cloudflare Tunnel Setup Script for Coolify
# This script creates Cloudflare tunnels for secure access to Coolify instances
# Based on KASM tunnel patterns with Coolify-specific optimizations

set -e

# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "❌ .env file not found in $SCRIPT_DIR"
    exit 1
fi

echo "🚀 Cloudflare Tunnel Setup for Coolify"
echo "======================================"
echo ""

# Validate required environment variables
required_vars=(
    "CLOUDFLARE_API_TOKEN"
    "CLOUDFLARE_ACCOUNT_ID" 
    "TUNNEL_NAME"
    "TUNNEL_HOSTNAME"
    "COOLIFY_SERVER_IP"
    "COOLIFY_PORT"
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
echo "   Coolify Server: $COOLIFY_SERVER_IP:$COOLIFY_PORT"
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
    TUNNEL_DOMAIN=$(echo "$TUNNEL_HOSTNAME" | cut -d'.' -f2-)
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
  --data "{\"type\":\"CNAME\",\"name\":\"$HOSTNAME_PART\",\"content\":\"$TUNNEL_DOMAIN_TARGET\",\"proxied\":true,\"comment\":\"Cloudflare Tunnel for Coolify\"}")

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

# Step 4: Configure Tunnel Ingress Rules for Coolify
echo "⚙️  Step 4: Configuring tunnel ingress rules for Coolify..."
INGRESS_CONFIG=$(cat <<EOF
{
  "config": {
    "ingress": [
      {
        "hostname": "$TUNNEL_HOSTNAME",
        "path": "*",
        "service": "http://$COOLIFY_SERVER_IP:$COOLIFY_PORT",
        "originRequest": {
          "connectTimeout": "30s",
          "tlsTimeout": "30s",
          "tcpKeepAlive": "30s",
          "keepAliveConnections": 10,
          "keepAliveTimeout": "90s",
          "httpHostHeader": "$COOLIFY_SERVER_IP:$COOLIFY_PORT",
          "originServerName": "$COOLIFY_SERVER_IP"
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

# Step 5: Generate Configuration Files
echo "📝 Step 5: Generating configuration files..."

# Create config directory
CONFIG_DIR="$SCRIPT_DIR/config"
mkdir -p "$CONFIG_DIR"

# Generate tunnel credentials file (placeholder - actual credentials need to be obtained from Cloudflare)
cat > "$CONFIG_DIR/$TUNNEL_ID.json" << EOF
{
  "AccountTag": "$CLOUDFLARE_ACCOUNT_ID",
  "TunnelID": "$TUNNEL_ID",
  "TunnelName": "$TUNNEL_NAME",
  "TunnelSecret": "PLACEHOLDER_SECRET_KEY"
}
EOF

# Generate tunnel config.yml
cat > "$CONFIG_DIR/config.yml" << EOF
tunnel: $TUNNEL_ID
credentials-file: /etc/cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $TUNNEL_HOSTNAME
    service: http://$COOLIFY_SERVER_IP:$COOLIFY_PORT
    originRequest:
      connectTimeout: 30s
      tlsTimeout: 30s
      tcpKeepAlive: 30s
      keepAliveConnections: 10
      keepAliveTimeout: 90s
      httpHostHeader: $COOLIFY_SERVER_IP:$COOLIFY_PORT
      originServerName: $COOLIFY_SERVER_IP
  - service: http_status:404
EOF

# Generate systemd service file
cat > "$CONFIG_DIR/cloudflared-$TUNNEL_NAME.service" << EOF
[Unit]
Description=Cloudflare Tunnel for Coolify
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloudflared tunnel --config /etc/cloudflared/config.yml run
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Generate deployment script
cat > "$CONFIG_DIR/deploy-tunnel.sh" << EOF
#!/bin/bash
# Deployment script for Coolify Cloudflare Tunnel

set -e

echo "🚀 Deploying Cloudflare Tunnel for Coolify..."

# Install cloudflared
echo "📥 Installing cloudflared..."
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64 -o cloudflared
sudo mv cloudflared /usr/local/bin/
sudo chmod +x /usr/local/bin/cloudflared

# Create cloudflared directory
echo "📁 Creating cloudflared directory..."
sudo mkdir -p /etc/cloudflared

# Copy configuration files
echo "📋 Copying configuration files..."
sudo cp $TUNNEL_ID.json /etc/cloudflared/
sudo cp config.yml /etc/cloudflared/

# Set proper permissions
echo "🔒 Setting permissions..."
sudo chmod 600 /etc/cloudflared/$TUNNEL_ID.json
sudo chmod 644 /etc/cloudflared/config.yml

# Install and start service
echo "🔧 Installing systemd service..."
sudo cp cloudflared-$TUNNEL_NAME.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable cloudflared-$TUNNEL_NAME
sudo systemctl start cloudflared-$TUNNEL_NAME

echo "✅ Tunnel deployment completed!"
echo "🔍 Check status: sudo systemctl status cloudflared-$TUNNEL_NAME"
echo "📋 View logs: sudo journalctl -u cloudflared-$TUNNEL_NAME -f"
EOF

chmod +x "$CONFIG_DIR/deploy-tunnel.sh"

echo "✅ Configuration files generated in: $CONFIG_DIR"
echo "   - Credentials: $CONFIG_DIR/$TUNNEL_ID.json"
echo "   - Config: $CONFIG_DIR/config.yml"
echo "   - Service: $CONFIG_DIR/cloudflared-$TUNNEL_NAME.service"
echo "   - Deployment Script: $CONFIG_DIR/deploy-tunnel.sh"

echo ""

# Step 6: Summary and Next Steps
echo "🎉 Cloudflare Tunnel Infrastructure Setup Complete!"
echo "=================================================="
echo ""
echo "📋 Summary:"
echo "   ✅ Tunnel created: $TUNNEL_ID"
echo "   ✅ DNS record configured: $TUNNEL_HOSTNAME"
echo "   ✅ Ingress rules set up for Coolify server"
echo "   ✅ Configuration files generated"
echo ""
echo "🚨 IMPORTANT: Manual Steps Required"
echo "=================================="
echo ""
echo "1. 📥 Deploy tunnel to your Coolify server:"
echo "   scp -r $CONFIG_DIR ubuntu@$COOLIFY_SERVER_IP:/tmp/tunnel-config"
echo "   ssh ubuntu@$COOLIFY_SERVER_IP 'cd /tmp/tunnel-config && sudo bash deploy-tunnel.sh'"
echo ""
echo "2. 🔑 Update credentials file with actual tunnel secret:"
echo "   - Get the tunnel secret from Cloudflare dashboard"
echo "   - Or use: cloudflared tunnel token $TUNNEL_NAME"
echo "   - Update the credentials file on the server"
echo ""
echo "3. 🧪 Test the connection:"
echo "   https://$TUNNEL_HOSTNAME"
echo ""
echo "4. 🔍 Monitor tunnel status:"
echo "   ssh ubuntu@$COOLIFY_SERVER_IP 'sudo systemctl status cloudflared-$TUNNEL_NAME'"
echo ""
echo "📄 All configuration details saved in: $SCRIPT_DIR/.env"
echo ""
echo "🌐 Expected Access URLs:"
echo "   Direct: http://$COOLIFY_SERVER_IP:$COOLIFY_PORT"
echo "   Tunnel: https://$TUNNEL_HOSTNAME"
echo ""
echo "✅ Tunnel setup completed! Deploy to server to activate."