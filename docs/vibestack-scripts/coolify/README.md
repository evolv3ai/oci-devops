# Cloudflare Tunnel Setup for Coolify Self-Host

This directory contains the complete Cloudflare Tunnel automation solution for deploying and exposing your Coolify self-hosted instance securely through Cloudflare's network.

## 🎯 Overview

This solution creates a secure tunnel from your Coolify server to Cloudflare, allowing access via `coolify.hdvfx.com` without opening inbound firewall ports. The tunnel provides:

- **Security**: No inbound ports needed on your server
- **Performance**: Cloudflare's global CDN acceleration
- **SSL/TLS**: Automatic certificate management
- **DDoS Protection**: Cloudflare's security features
- **IPv4/IPv6**: Dual-stack connectivity
- **Self-Hosting**: Complete control over your deployment platform

## 📁 Files in This Directory

### Core Scripts
- **`oci-coolify-infrastructure-setup.sh`** - OCI infrastructure deployment script (compartment, VCN, subnet, instance)
- **`coolify-installation.sh`** - Coolify installation script for OCI ARM64 instances
- **`coolify-cloudflare-tunnel-setup.sh`** - Main automation script that creates the complete tunnel infrastructure
- **`coolify-fix-dns.sh`** - DNS troubleshooting script to fix resolution issues
- **`.env.example`** - Example environment configuration file
- **`README.md`** - This documentation file

### Generated Files (after running setup)
- **`config/tunnel-credentials.json`** - Tunnel authentication credentials
- **`config/config.yml`** - Tunnel daemon configuration
- **`config/cloudflared-coolify-tunnel.service`** - Systemd service file for tunnel daemon
- **`config/deploy-tunnel.sh`** - Automated deployment script for tunnel
- **`coolify-access.txt`** - Coolify admin credentials and access information

## 🚀 Quick Start

### Prerequisites
- Oracle Cloud Infrastructure (OCI) account with CLI configured
- Cloudflare account with domain management access
- Cloudflare API token with Zone:Edit permissions
- SSH key pair for instance access

### Step 1: Configure Environment
1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Update the `.env` file with your specific details:
   ```bash
   # OCI Configuration
   TENANCY_OCID="ocid1.tenancy.oc1..your_tenancy_ocid_here"
   REGION="us-ashburn-1"
   SSH_KEY_PATH="/path/to/your/ssh/public/key.pub"
   
   # Cloudflare Configuration
   CLOUDFLARE_API_TOKEN="your_api_token_here"
   TUNNEL_HOSTNAME="coolify.hdvfx.com"
   
   # Coolify Configuration
   ROOT_USERNAME="admin"
   ROOT_USER_EMAIL="admin@coolify.local"
   ROOT_USER_PASSWORD="your_secure_password_here"
   ```

### Step 2: Deploy OCI Infrastructure
```bash
# Make scripts executable
chmod +x oci-coolify-infrastructure-setup.sh coolify-installation.sh coolify-cloudflare-tunnel-setup.sh coolify-fix-dns.sh

# Deploy complete OCI infrastructure
./oci-coolify-infrastructure-setup.sh
```

### Step 3: Install Coolify
```bash
# Install Coolify on the deployed instance
./coolify-installation.sh
```

### Step 4: Set up Cloudflare Tunnel
```bash
# Run the tunnel setup script
./coolify-cloudflare-tunnel-setup.sh
```

### Step 5: Deploy Tunnel to Server
```bash
# Deploy tunnel configuration to your server
scp -r config ubuntu@YOUR_SERVER_IP:/tmp/tunnel-config
ssh ubuntu@YOUR_SERVER_IP 'cd /tmp/tunnel-config && sudo bash deploy-tunnel.sh'
```

### Step 6: Fix DNS (if needed)
If you encounter DNS resolution issues:
```bash
./coolify-fix-dns.sh
```

## 📋 Detailed Process

### OCI Infrastructure Setup Process

The `oci-coolify-infrastructure-setup.sh` script performs the following steps:

1. **Environment Validation**
   - Validates all required OCI environment variables
   - Checks OCI CLI connectivity and authentication
   - Verifies SSH key file existence

2. **Compartment Creation**
   - Creates CoolifyLab compartment under tenancy
   - Isolates all Coolify resources for organization
   - Handles existing compartment gracefully

3. **Network Infrastructure**
   - Creates Virtual Cloud Network (VCN) with 10.0.0.0/16 CIDR
   - Creates public subnet with 10.0.1.0/24 CIDR
   - Sets up Internet Gateway for external connectivity
   - Configures default route table for internet access

4. **Security Configuration**
   - Creates custom security list for Coolify traffic
   - Opens required ports: SSH (22), Coolify Web (8000), HTTP (80), HTTPS (443), Proxy (6001-6002)
   - Associates security list with subnet
   - Configures egress rules for outbound traffic

5. **Compute Instance Deployment**
   - Finds latest Ubuntu 22.04 ARM64 image
   - Deploys VM.Standard.A1.Flex instance (2 OCPUs, 12GB RAM, 100GB storage)
   - Assigns public IP for external access
   - Configures SSH key authentication
   - Waits for instance to reach RUNNING state

6. **Connectivity Verification**
   - Retrieves public and private IP addresses
   - Tests SSH connectivity to verify deployment
   - Saves all configuration to .env file
   - Provides access information and next steps

### Coolify Installation Process

The `coolify-installation.sh` script performs the following steps:

1. **System Verification**
   - Checks OS version (Ubuntu 22.04 ARM64)
   - Verifies system resources (memory, storage)
   - Updates system packages

2. **Docker Installation**
   - Installs Docker CE and Docker Compose
   - Configures Docker service
   - Adds user to docker group

3. **Coolify Installation**
   - Downloads and runs Coolify automated installer
   - Configures root user with provided credentials
   - Sets up all required services and containers

4. **Service Verification**
   - Verifies all Coolify containers are running
   - Tests web interface accessibility
   - Checks service ports

5. **Security Configuration**
   - Configures UFW firewall
   - Opens required ports (8000, 80, 443, 6001, 6002)
   - Secures SSH access

6. **Access Information**
   - Saves admin credentials and access URLs
   - Provides management commands
   - Downloads credentials file locally

### Cloudflare Tunnel Setup Process

The `coolify-cloudflare-tunnel-setup.sh` script performs the following steps:

1. **Environment Validation**
   - Checks all required environment variables
   - Validates Cloudflare API connectivity
   - Verifies domain zone access

2. **Tunnel Infrastructure Creation**
   - Creates a new Cloudflare tunnel via API
   - Generates tunnel credentials and configuration
   - Sets up optimized ingress rules for Coolify

3. **DNS Configuration**
   - Creates CNAME record pointing to tunnel endpoint
   - Configures Cloudflare proxy (orange cloud) for performance
   - Handles IPv4/IPv6 dual-stack resolution

4. **Public Hostname Routes**
   - Configures tunnel routing for your domain
   - Sets up HTTP handling for Coolify web interface
   - Optimizes settings for web application traffic

5. **Deployment Preparation**
   - Generates all necessary configuration files
   - Creates systemd service file for tunnel daemon
   - Provides deployment scripts and instructions

### Configuration Details

#### Tunnel Configuration (`config.yml`)
```yaml
tunnel: f76c76d4-620f-4ff1-8d60-743f0c008a39
credentials-file: /etc/cloudflared/f76c76d4-620f-4ff1-8d60-743f0c008a39.json

ingress:
  - hostname: coolify.hdvfx.com
    service: http://localhost:8000
    originRequest:
      connectTimeout: 30s
      tlsTimeout: 30s
      tcpKeepAlive: 30s
      keepAliveConnections: 10
      keepAliveTimeout: 90s
  - service: http_status:404
```

#### Key Features
- **HTTP Support**: Direct HTTP connection to Coolify (no TLS verification needed)
- **Optimized Timeouts**: Configured for web application requirements
- **Connection Pooling**: Maintains persistent connections for better performance
- **Fallback Handling**: 404 response for unmatched requests

## 🔧 Troubleshooting

### Common Issues

#### 1. DNS Resolution Problems
**Symptoms**: `DNS_PROBE_FINISHED_NXDOMAIN` or only IPv6 resolution

**Solution**: Run the DNS fix script
```bash
./coolify-fix-dns.sh
```

This ensures the CNAME record is properly proxied through Cloudflare.

#### 2. Tunnel Connection Issues
**Check tunnel status on server**:
```bash
sudo systemctl status cloudflared-coolify-tunnel
sudo journalctl -u cloudflared-coolify-tunnel -f
```

#### 3. Coolify Access Issues
**Verify Coolify is running**:
```bash
sudo docker ps | grep coolify
curl -I http://localhost:8000
```

#### 4. Coolify Not Starting
**Check Coolify logs**:
```bash
sudo docker logs coolify
sudo docker compose -f /data/coolify/source/docker-compose.yml logs
```

### DNS Verification
```bash
# Check DNS resolution
nslookup coolify.hdvfx.com
dig coolify.hdvfx.com

# Should return both IPv4 and IPv6 addresses when properly configured
```

### Tunnel Testing
```bash
# Test tunnel connectivity
curl -I https://coolify.hdvfx.com

# Should return Coolify web interface headers
```

### Coolify Service Management
```bash
# Check all Coolify containers
sudo docker ps | grep coolify

# Restart Coolify
sudo docker restart coolify

# Update Coolify
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

## 📊 Infrastructure Details

### Created Resources

#### OCI Resources
- **Compartment**: `CoolifyLab`
- **VCN**: `CoolifyVCN` (10.0.0.0/16)
- **Subnet**: `CoolifySubnet` (10.0.1.0/24)
- **Instance**: `CoolifyInstance` (VM.Standard.A1.Flex, 2 OCPUs, 12GB RAM, 100GB storage)
- **Security List**: Custom rules for Coolify traffic

#### Cloudflare Resources
- **Tunnel**: `coolify-tunnel`
- **DNS Record**: `coolify.hdvfx.com` → `{tunnel-id}.cfargotunnel.com`
- **Public Hostname**: Route configuration for Coolify traffic

#### Server Resources
- **Service**: `cloudflared-coolify-tunnel.service`
- **Config Directory**: `/etc/cloudflared/`
- **Credentials**: `/etc/cloudflared/{tunnel-id}.json`
- **Configuration**: `/etc/cloudflared/config.yml`

### Network Flow
```
User Browser → Cloudflare Edge → Tunnel → Coolify Server:8000
```

## 🔐 Security Considerations

### Firewall Configuration
- **No inbound ports required** on Coolify server (except SSH)
- Tunnel creates outbound connection to Cloudflare
- All traffic encrypted end-to-end

### SSL/TLS Handling
- Cloudflare provides public SSL certificate
- Tunnel handles HTTP connection to Coolify
- No certificate management required on server

### Access Control
- Cloudflare's security features apply automatically
- Can add additional Cloudflare Access rules if needed
- DDoS protection included
- Coolify has built-in authentication

## 📈 Performance Optimization

### Cloudflare Features
- **Global CDN**: Static assets cached worldwide
- **Smart Routing**: Optimal path selection
- **HTTP/2 & HTTP/3**: Modern protocol support
- **Compression**: Automatic content optimization

### Coolify-Specific Optimizations
- **Connection Pooling**: Maintains persistent connections
- **Timeout Tuning**: Optimized for web application traffic
- **Direct HTTP**: Eliminates TLS overhead between tunnel and Coolify

## 🔄 Maintenance

### Regular Tasks
1. **Monitor tunnel health**: Check systemd service status
2. **Review logs**: Monitor for connection issues
3. **Update cloudflared**: Keep tunnel daemon current
4. **Update Coolify**: Keep platform current
5. **Backup credentials**: Secure tunnel credentials file

### Updates
```bash
# Update cloudflared daemon
sudo cloudflared update

# Restart tunnel service
sudo systemctl restart cloudflared-coolify-tunnel

# Update Coolify
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
```

### Backup and Recovery
```bash
# Backup Coolify data
sudo docker exec coolify pg_dump -U postgres coolify > coolify-backup.sql

# Backup tunnel configuration
sudo cp -r /etc/cloudflared /backup/cloudflared-config
```

## 📞 Support

### Log Locations
- **Tunnel Logs**: `sudo journalctl -u cloudflared-coolify-tunnel`
- **Coolify Logs**: `sudo docker logs coolify`
- **System Logs**: `/var/log/syslog`

### Useful Commands
```bash
# Check tunnel status
sudo systemctl status cloudflared-coolify-tunnel

# View real-time tunnel logs
sudo journalctl -u cloudflared-coolify-tunnel -f

# Test local Coolify connectivity
curl -I http://localhost:8000

# Test external connectivity
curl -I https://coolify.hdvfx.com

# Check Coolify containers
sudo docker ps | grep coolify

# Access Coolify database
sudo docker exec -it coolify-database psql -U postgres coolify
```

## ✅ Success Criteria

Your Coolify tunnel is working correctly when:

1. **DNS Resolution**: `coolify.hdvfx.com` resolves to both IPv4 and IPv6
2. **HTTP Response**: `curl -I https://coolify.hdvfx.com` returns Coolify headers
3. **Browser Access**: `https://coolify.hdvfx.com` loads Coolify login page
4. **Service Status**: `systemctl status cloudflared-coolify-tunnel` shows active
5. **No Errors**: Tunnel logs show successful connections
6. **Coolify Functional**: Can log in and deploy applications

## 🎉 Completion

Once deployed, your Coolify instance will be securely accessible at:
**https://coolify.hdvfx.com**

The tunnel provides enterprise-grade security, performance, and reliability for your self-hosted application deployment platform.

### What You Can Do Next

1. **Deploy Applications**: Use Coolify to deploy Docker containers, static sites, and more
2. **Set Up Databases**: Create PostgreSQL, MySQL, Redis, and other database instances
3. **Configure Services**: Deploy pre-configured services like WordPress, Ghost, etc.
4. **Team Collaboration**: Add team members and manage permissions
5. **CI/CD Integration**: Connect with GitHub, GitLab, and other Git providers
6. **Monitoring**: Set up application monitoring and alerts
7. **Scaling**: Add additional servers to your Coolify cluster

---

*Generated by Coolify Cloudflare Tunnel Automation - KASM Container Admin*