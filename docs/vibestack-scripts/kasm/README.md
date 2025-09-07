# KASM Workspaces on Oracle Cloud Infrastructure with Cloudflare Tunnel

This directory contains the complete automation solution for deploying KASM Workspaces on Oracle Cloud Infrastructure (OCI) and exposing it securely through Cloudflare's network.

## 🎯 Overview

This solution provides an end-to-end deployment that:

1. **Creates OCI Infrastructure**: Sets up a complete Oracle Cloud environment with networking and compute resources
2. **Installs KASM Workspaces**: Deploys KASM container-based virtual desktop infrastructure
3. **Configures Cloudflare Tunnel**: Securely exposes KASM via `k2.hdvfx.com` without opening firewall ports

### Key Benefits
- **Complete Automation**: One-click deployment from infrastructure to access
- **Security**: No inbound ports needed, all traffic through Cloudflare tunnel
- **Performance**: Cloudflare's global CDN acceleration
- **SSL/TLS**: Automatic certificate management
- **DDoS Protection**: Cloudflare's security features
- **Cost-Effective**: Uses OCI's ARM64 instances (free tier eligible)

## 📁 Files in This Directory

### Core Scripts (in execution order)
1. **`oci-infrastructure-setup.sh`** - Creates OCI infrastructure (compartment, VCN, subnet, instance)
2. **`kasm-installation.sh`** - Installs KASM Workspaces on the OCI instance
3. **`cloudflare-tunnel-setup.sh`** - Sets up Cloudflare tunnel for secure access
4. **`fix-dns.sh`** - DNS troubleshooting script (if needed)

### Configuration Files
- **`.env`** - Environment configuration with all required variables
- **`.env.example`** - Example environment configuration file
- **`README.md`** - This documentation file

### Generated Files (created during setup)
- **`tunnel-credentials.json`** - Cloudflare tunnel authentication credentials
- **`tunnel-config.yml`** - Cloudflare tunnel daemon configuration
- **`cloudflared-service.service`** - Systemd service file for tunnel daemon

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
   TUNNEL_HOSTNAME="k2.hdvfx.com"
   ```

### Step 2: Make Scripts Executable
```bash
chmod +x oci-infrastructure-setup.sh kasm-installation.sh cloudflare-tunnel-setup.sh fix-dns.sh
```

### Step 3: Deploy OCI Infrastructure
```bash
# Creates compartment, VCN, subnet, and compute instance
./oci-infrastructure-setup.sh
```
This will output the instance's public IP address and update your `.env` file.

### Step 4: Install KASM Workspaces
```bash
# SSH into the instance and install KASM
./kasm-installation.sh
```
This will install Docker, KASM Workspaces, and configure the firewall.

### Step 5: Set up Cloudflare Tunnel
```bash
# Create tunnel and configure DNS
./cloudflare-tunnel-setup.sh
```
This generates tunnel configuration files and sets up the DNS record.

### Step 6: Deploy Tunnel to Server
The tunnel setup script will provide deployment instructions. You can either:

**Option A: Manual Deployment (Recommended)**
1. Copy the generated files to your KASM server
2. Follow the deployment instructions shown by the script

**Option B: Automated SSH Deployment**
The script can automatically deploy via SSH if configured.

### Step 7: Verify Access
Once deployed, access your KASM instance at:
```
https://k2.hdvfx.com
```

### Troubleshooting DNS (if needed)
If you encounter DNS resolution issues:
```bash
./fix-dns.sh
```

## 📋 Detailed Process

### Phase 1: OCI Infrastructure Setup

The `oci-infrastructure-setup.sh` script creates your Oracle Cloud environment:

1. **Environment Validation**
   - Validates all required OCI environment variables
   - Checks OCI CLI connectivity and authentication
   - Verifies SSH key file existence

2. **Compartment Creation**
   - Creates KasmLab compartment under tenancy
   - Isolates all KASM resources for organization
   - Handles existing compartment gracefully

3. **Network Infrastructure**
   - Creates Virtual Cloud Network (VCN) with 10.0.0.0/16 CIDR
   - Creates public subnet with 10.0.1.0/24 CIDR
   - Sets up Internet Gateway for external connectivity
   - Configures default route table for internet access

4. **Security Configuration**
   - Creates custom security list for KASM traffic
   - Opens required ports: SSH (22), KASM Web (8443), RDP (3389), Sessions (3000-4000)
   - Associates security list with subnet
   - Configures egress rules for outbound traffic

5. **Compute Instance Deployment**
   - Finds latest Ubuntu 22.04 ARM64 image
   - Deploys VM.Standard.A1.Flex instance (2 OCPUs, 12GB RAM)
   - Assigns public IP for external access
   - Configures SSH key authentication
   - Waits for instance to reach RUNNING state

6. **Connectivity Verification**
   - Retrieves public and private IP addresses
   - Tests SSH connectivity to verify deployment
   - Saves all configuration to .env file
   - Provides access information and next steps

### Phase 2: KASM Installation

The `kasm-installation.sh` script installs KASM Workspaces on your OCI instance:

1. **System Verification**
   - Checks OS version (Ubuntu 22.04 ARM64)
   - Verifies system resources (memory, storage)
   - Updates system packages

2. **Docker Installation**
   - Installs Docker CE and Docker Compose
   - Configures Docker service
   - Adds user to docker group

3. **KASM Workspaces Installation**
   - Downloads KASM release 1.17.0
   - Runs automated installation
   - Configures services and containers

4. **Service Verification**
   - Verifies all KASM containers are running
   - Tests web interface accessibility
   - Checks service ports

5. **Security Configuration**
   - Configures UFW firewall
   - Opens required ports (8443, 3389, 3000-4000)
   - Secures SSH access

6. **Credential Retrieval**
   - Extracts admin credentials from installation logs
   - Provides access information

### Phase 3: Cloudflare Tunnel Setup

The `cloudflare-tunnel-setup.sh` script creates secure external access:

1. **Environment Validation**
   - Checks all required environment variables
   - Validates Cloudflare API connectivity
   - Verifies domain zone access

2. **Tunnel Infrastructure Creation**
   - Creates a new Cloudflare tunnel via API
   - Generates tunnel credentials and configuration
   - Sets up optimized ingress rules for KASM

3. **DNS Configuration**
   - Creates CNAME record pointing to tunnel endpoint
   - Configures Cloudflare proxy (orange cloud) for performance
   - Handles IPv4/IPv6 dual-stack resolution

4. **Public Hostname Routes**
   - Configures tunnel routing for your domain
   - Sets up SSL/TLS handling for self-signed certificates
   - Optimizes settings for KASM Workspaces

5. **Deployment Preparation**
   - Generates all necessary configuration files
   - Creates systemd service file for tunnel daemon
   - Provides deployment scripts and instructions

## 🔧 Configuration Details

### Environment Variables (.env)
```bash
# OCI Configuration
TENANCY_OCID="ocid1.tenancy.oc1..xxxxx"
REGION="us-ashburn-1"
SSH_KEY_PATH="/path/to/ssh/key.pub"
COMPARTMENT_NAME="KasmLab"
VCN_NAME="kasm-vcn"
SUBNET_NAME="kasm-public-subnet"
INSTANCE_NAME="kasm-server"

# Cloudflare Configuration
CLOUDFLARE_API_TOKEN="your_api_token"
TUNNEL_HOSTNAME="k2.hdvfx.com"
TUNNEL_NAME="k2-tunnel"

# Generated by scripts
COMPARTMENT_OCID="ocid1.compartment.oc1..xxxxx"
INSTANCE_PUBLIC_IP="xxx.xxx.xxx.xxx"
INSTANCE_PRIVATE_IP="10.0.1.x"
```

### Tunnel Configuration (`tunnel-config.yml`)
```yaml
tunnel: f76c76d4-620f-4ff1-8d60-743f0c008a39
credentials-file: /etc/cloudflared/tunnel-credentials.json

ingress:
  - hostname: k2.hdvfx.com
    service: https://localhost:8443
    originRequest:
      noTLSVerify: true
      connectTimeout: 30s
      tlsTimeout: 30s
      tcpKeepAlive: 30s
      keepAliveConnections: 10
      keepAliveTimeout: 90s
  - service: http_status:404
```

### Key Configuration Features
- **SSL Bypass**: `noTLSVerify: true` handles KASM's self-signed certificates
- **Optimized Timeouts**: Configured for KASM's desktop streaming requirements
- **Connection Pooling**: Maintains persistent connections for better performance

## 🔧 Troubleshooting

### Common Issues

#### 1. OCI Instance Creation Fails
**Possible causes**:
- Insufficient quota for ARM instances
- SSH key not found or invalid
- OCI CLI not configured properly

**Solutions**:
```bash
# Check OCI CLI configuration
oci iam region list

# Verify SSH key
ls -la ~/.ssh/id_rsa.pub

# Check quotas
oci limits value list --compartment-id <tenancy-ocid> --service-name compute
```

#### 2. KASM Installation Issues
**Verify system requirements**:
```bash
# Check Ubuntu version
lsb_release -a

# Check available memory
free -h

# Check Docker installation
docker --version
```

#### 3. DNS Resolution Problems
**Symptoms**: `DNS_PROBE_FINISHED_NXDOMAIN` or only IPv6 resolution

**Solution**: Run the DNS fix script
```bash
./fix-dns.sh
```

#### 4. Tunnel Connection Issues
**Check tunnel status on server**:
```bash
sudo systemctl status cloudflared-k2-tunnel
sudo journalctl -u cloudflared-k2-tunnel -f
```

#### 5. KASM Access Issues
**Verify KASM is running**:
```bash
sudo docker ps | grep kasm
curl -k https://localhost:8443
```

### Verification Commands

#### DNS Verification
```bash
# Check DNS resolution
nslookup k2.hdvfx.com
dig k2.hdvfx.com

# Should return both IPv4 and IPv6 addresses when properly configured
```

#### Tunnel Testing
```bash
# Test tunnel connectivity
curl -I https://k2.hdvfx.com

# Should return KASM login page headers
```

#### OCI Instance Connectivity
```bash
# Test SSH access
ssh -i <private-key-path> ubuntu@<instance-public-ip>

# Check instance status
oci compute instance get --instance-id <instance-ocid>
```

## 📊 Infrastructure Details

### Created Resources

#### OCI Resources
- **Compartment**: KasmLab
- **VCN**: kasm-vcn (10.0.0.0/16)
- **Subnet**: kasm-public-subnet (10.0.1.0/24)
- **Internet Gateway**: kasm-igw
- **Security List**: kasm-security-list
- **Compute Instance**: kasm-server (VM.Standard.A1.Flex, 2 OCPU, 12GB RAM)

#### KASM Resources
- **Docker Containers**: Multiple KASM service containers
- **Web Interface**: Port 8443 (HTTPS)
- **RDP Gateway**: Port 3389
- **Session Ports**: 3000-4000

#### Cloudflare Resources
- **Tunnel**: k2-tunnel (UUID: f76c76d4-620f-4ff1-8d60-743f0c008a39)
- **DNS Record**: k2.hdvfx.com → tunnel CNAME
- **Public Hostname**: Route configuration for KASM traffic

#### Server Resources
- **Service**: `cloudflared-k2-tunnel.service`
- **Config Directory**: `/etc/cloudflared/`
- **Credentials**: `/etc/cloudflared/tunnel-credentials.json`
- **Configuration**: `/etc/cloudflared/config.yml`

### Network Flow
```
User Browser → Cloudflare Edge → Tunnel → OCI Instance → KASM:8443
             ↓                           ↓
         (Global CDN)              (No inbound ports)
```

## 🔐 Security Considerations

### OCI Security
- **Compartment Isolation**: All resources in dedicated compartment
- **Security Lists**: Only required ports open (SSH, KASM, RDP)
- **Private Network**: Internal communication on private subnet

### KASM Security
- **Container Isolation**: Each session runs in isolated container
- **SSL/TLS**: HTTPS-only access on port 8443
- **Authentication**: Built-in user management and MFA support

### Cloudflare Security
- **No Inbound Ports**: Tunnel creates outbound connection only
- **End-to-End Encryption**: All traffic encrypted
- **DDoS Protection**: Cloudflare's automatic protection
- **Access Control**: Can add Cloudflare Access rules
- **SSL Certificate**: Cloudflare manages public certificates

## 📈 Performance Optimization

### OCI Optimizations
- **ARM Architecture**: Cost-effective high performance
- **Local NVMe**: Fast storage for containers
- **Network Bandwidth**: Up to 4 Gbps network performance

### Cloudflare Features
- **Global CDN**: Static assets cached worldwide
- **Smart Routing**: Optimal path selection
- **HTTP/2 & HTTP/3**: Modern protocol support
- **Compression**: Automatic content optimization

### KASM-Specific Optimizations
- **Connection Pooling**: Maintains persistent connections
- **Timeout Tuning**: Optimized for desktop streaming
- **SSL Bypass**: Eliminates certificate overhead
- **Resource Allocation**: Proper CPU/memory for workloads

## 🔄 Maintenance

### Regular Tasks

#### OCI Maintenance
1. **Monitor instance health**: Check compute metrics
2. **Update system packages**: Keep Ubuntu current
3. **Review security lists**: Ensure proper access control
4. **Check resource usage**: Monitor CPU/memory/storage

#### KASM Maintenance
1. **Update KASM**: Check for new releases
2. **Container cleanup**: Remove unused images
3. **User management**: Review access permissions
4. **Backup configuration**: Save KASM settings

#### Cloudflare Maintenance
1. **Monitor tunnel health**: Check systemd service status
2. **Review logs**: Monitor for connection issues
3. **Update cloudflared**: Keep tunnel daemon current
4. **Backup credentials**: Secure tunnel credentials file

### Update Commands
```bash
# System updates
sudo apt update && sudo apt upgrade

# Docker updates
sudo apt update docker-ce docker-ce-cli

# Cloudflared updates
sudo cloudflared update

# Restart services
sudo systemctl restart docker
sudo systemctl restart cloudflared-k2-tunnel
```

## 📞 Support

### Log Locations
- **OCI Logs**: OCI Console → Compute → Instance → Metrics
- **System Logs**: `/var/log/syslog`, `/var/log/cloud-init.log`
- **Docker Logs**: `sudo docker logs <container-id>`
- **KASM Logs**: `/opt/kasm/current/log/`
- **Tunnel Logs**: `sudo journalctl -u cloudflared-k2-tunnel`

### Useful Commands
```bash
# OCI instance status
oci compute instance get --instance-id <instance-ocid>

# SSH to instance
ssh -i <private-key> ubuntu@<public-ip>

# Check KASM services
sudo docker ps | grep kasm

# Check tunnel status
sudo systemctl status cloudflared-k2-tunnel

# View real-time tunnel logs
sudo journalctl -u cloudflared-k2-tunnel -f

# Test local KASM connectivity
curl -k https://localhost:8443

# Test external connectivity
curl -I https://k2.hdvfx.com
```

## ✅ Success Criteria

Your deployment is successful when:

### OCI Infrastructure
1. **Instance Running**: OCI console shows instance in RUNNING state
2. **SSH Access**: Can SSH to instance using provided key
3. **Network Connectivity**: Instance can reach internet

### KASM Installation
1. **Docker Running**: `docker ps` shows containers active
2. **Web Interface**: `https://<public-ip>:8443` loads login page
3. **Admin Access**: Can login with provided credentials

### Cloudflare Tunnel
1. **DNS Resolution**: `k2.hdvfx.com` resolves to both IPv4 and IPv6
2. **HTTP Response**: `curl -I https://k2.hdvfx.com` returns KASM headers
3. **Browser Access**: `https://k2.hdvfx.com` loads KASM login page
4. **Service Status**: `systemctl status cloudflared-k2-tunnel` shows active
5. **No Errors**: Tunnel logs show successful connections

## 🎉 Completion

Once all steps are complete, your KASM Workspaces will be:
- **Running on OCI**: Cost-effective ARM infrastructure
- **Fully Configured**: With Docker and all required services
- **Securely Accessible**: At **https://k2.hdvfx.com**

The complete solution provides enterprise-grade security, performance, and reliability for your virtual desktop infrastructure.

---

*KASM Workspaces on OCI with Cloudflare Tunnel - Complete Deployment Solution*