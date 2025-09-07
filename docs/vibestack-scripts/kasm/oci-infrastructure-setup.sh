#!/bin/bash

# OCI Infrastructure Setup Script for KASM Workspaces
# This is a wrapper that calls the centralized OCI infrastructure setup script
# Located in the /oci folder for DRY principle compliance

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OCI_DIR="$(cd "$SCRIPT_DIR/../oci" && pwd)"

echo "ðŸš€ KASM Infrastructure Setup (using centralized OCI scripts)"
echo "============================================================"
echo ""

# Check if centralized script exists
if [ ! -f "$OCI_DIR/oci-infrastructure-setup.sh" ]; then
    echo "âŒ Error: Centralized infrastructure script not found at $OCI_DIR/oci-infrastructure-setup.sh"
    exit 1
fi

# Check if .env exists in oci directory
if [ ! -f "$OCI_DIR/.env" ]; then
    echo "âŒ Error: .env file not found in $OCI_DIR"
    echo "Please configure $OCI_DIR/.env first"
    exit 1
fi

# Call the centralized infrastructure setup script with 'kasm' parameter
echo "ðŸ”§ Calling centralized OCI infrastructure setup for KASM..."
echo ""
bash "$OCI_DIR/oci-infrastructure-setup.sh" kasm

# Check if the script completed successfully
if [ $? -eq 0 ]; then
    echo ""
    echo "ðŸŽ‰ KASM infrastructure setup completed successfully!"
    echo ""
    echo "Next steps:"
    echo "  1. Run the KASM installation script:"
    echo "     bash $SCRIPT_DIR/kasm-installation.sh"
    echo ""
    echo "  2. Set up Cloudflare tunnel (optional):"
    echo "     bash $SCRIPT_DIR/cloudflare-tunnel-setup.sh"
    echo ""
else
    echo ""
    echo "âŒ Infrastructure setup failed. Please check the error messages above."
    exit 1
fi

# Load server-specific configuration based on server type
case "$SERVER_TYPE" in
    kasm)
        INSTANCE_OCPUS="${KASM_OCPUS:-4}"
        INSTANCE_MEMORY_GB="${KASM_MEMORY_GB:-24}"
        DISPLAY_NAME_PREFIX="${KASM_PREFIX:-KASM-}"
        SERVER_DESCRIPTION="KASM Workspaces"
        SECURITY_PORTS='[
            {"protocol":"6","source":"0.0.0.0/0","isStateless":false,"tcpOptions":{"destinationPortRange":{"min":22,"max":22}}},
            {"protocol":"6","source":"0.0.0.0/0","isStateless":false,"tcpOptions":{"destinationPortRange":{"min":8443,"max":8443}}},
            {"protocol":"6","source":"0.0.0.0/0","isStateless":false,"tcpOptions":{"destinationPortRange":{"min":3389,"max":3389}}},
            {"protocol":"6","source":"0.0.0.0/0","isStateless":false,"tcpOptions":{"destinationPortRange":{"min":3000,"max":4000}}}
        ]'
        ;;
    coolify)
        INSTANCE_OCPUS="${COOLIFY_OCPUS:-2}"
        INSTANCE_MEMORY_GB="${COOLIFY_MEMORY_GB:-12}"
        DISPLAY_NAME_PREFIX="${COOLIFY_PREFIX:-Coolify-}"
        SERVER_DESCRIPTION="Coolify Self-Host"
        SECURITY_PORTS='[
            {"protocol":"6","source":"0.0.0.0/0","isStateless":false,"tcpOptions":{"destinationPortRange":{"min":22,"max":22}}},
            {"protocol":"6","source":"0.0.0.0/0","isStateless":false,"tcpOptions":{"destinationPortRange":{"min":8000,"max":8000}}},
            {"protocol":"6","source":"0.0.0.0/0","isStateless":false,"tcpOptions":{"destinationPortRange":{"min":80,"max":80}}},
            {"protocol":"6","source":"0.0.0.0/0","isStateless":false,"tcpOptions":{"destinationPortRange":{"min":443,"max":443}}},
            {"protocol":"6","source":"0.0.0.0/0","isStateless":false,"tcpOptions":{"destinationPortRange":{"min":6001,"max":6001}}},
            {"protocol":"6","source":"0.0.0.0/0","isStateless":false,"tcpOptions":{"destinationPortRange":{"min":6002,"max":6002}}}
        ]'
        ;;
    *)
        echo "âŒ Unknown server type: $SERVER_TYPE"
        echo "Usage: $0 [kasm|coolify]"
        exit 1
        ;;
esac

# Required environment variables for OCI infrastructure
REQUIRED_VARS=(
    "TENANCY_OCID"
    "REGION"
    "COMPARTMENT_NAME"
    "VCN_CIDR"
    "SUBNET_CIDR"
    "SSH_KEY_PATH"
    "INSTANCE_SHAPE"
    "OPERATING_SYSTEM"
    "OPERATING_SYSTEM_VERSION"
)

echo "ðŸš€ OCI Infrastructure Setup for $SERVER_DESCRIPTION"
echo "ðŸ—ï¸  Creating complete infrastructure on Oracle Cloud"
echo "ðŸ“‹ Server Type: $SERVER_TYPE"
echo "ðŸ“‹ Tenancy: $TENANCY_OCID"
echo "ðŸŒ Region: $REGION"
echo "ðŸ“¦ Compartment: $COMPARTMENT_NAME"
echo "ðŸ”§ Instance: $INSTANCE_SHAPE ($INSTANCE_OCPUS OCPUs, ${INSTANCE_MEMORY_GB}GB RAM)"
echo "ðŸ·ï¸  Display Name Prefix: $DISPLAY_NAME_PREFIX"
echo ""

# Validate required environment variables
echo "ðŸ“‹ Validating environment configuration..."
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "âŒ Missing required environment variable: $var"
        exit 1
    fi
    echo "âœ… $var: ${!var}"
done
echo ""

# Function to run OCI CLI commands with error handling
run_oci_command() {
    local command="$1"
    local description="$2"
    local capture_output="$3"
    
    echo "ðŸ”§ $description"
    echo "ðŸ“ Executing: $command"
    
    if [ "$capture_output" = "true" ]; then
        local output
        if output=$(eval "$command" 2>&1); then
            echo "âœ… $description completed successfully"
            echo "$output"
            echo ""
            return 0
        else
            echo "âŒ $description failed"
            echo "Error output: $output"
            echo ""
            return 1
        fi
    else
        if eval "$command"; then
            echo "âœ… $description completed successfully"
            echo ""
            return 0
        else
            echo "âŒ $description failed"
            echo ""
            return 1
        fi
    fi
}

# Step 1: Create compartment
echo "ðŸ“¦ Step 1: Creating $COMPARTMENT_NAME compartment..."
COMPARTMENT_CMD="oci iam compartment create \
  --compartment-id $TENANCY_OCID \
  --name $COMPARTMENT_NAME \
  --description 'Compartment for $SERVER_DESCRIPTION deployment' \
  --wait-for-state ACTIVE"

if ! run_oci_command "$COMPARTMENT_CMD" "Creating $COMPARTMENT_NAME compartment"; then
    echo "âš ï¸  Compartment might already exist, continuing..."
fi

# Get compartment ID
echo "ðŸ” Retrieving compartment ID..."
COMPARTMENT_ID_CMD="oci iam compartment list \
  --compartment-id $TENANCY_OCID \
  --name $COMPARTMENT_NAME \
  --query 'data[0].id' \
  --raw-output"

if COMPARTMENT_ID=$(eval "$COMPARTMENT_ID_CMD"); then
    echo "âœ… Compartment ID: $COMPARTMENT_ID"
    export COMPARTMENT_ID
    echo ""
else
    echo "âŒ Failed to retrieve compartment ID"
    exit 1
fi

# Step 2: Create Virtual Cloud Network (VCN)
echo "ðŸŒ Step 2: Creating Virtual Cloud Network..."
VCN_CMD="oci network vcn create \
  --compartment-id $COMPARTMENT_ID \
  --display-name '${DISPLAY_NAME_PREFIX}VCN' \
  --cidr-block $VCN_CIDR \
  --dns-label kasmvcn \
  --wait-for-state AVAILABLE"

if ! run_oci_command "$VCN_CMD" "Creating VCN"; then
    echo "âš ï¸  VCN might already exist, continuing..."
fi

# Get VCN ID
echo "ðŸ” Retrieving VCN ID..."
VCN_ID_CMD="oci network vcn list \
  --compartment-id $COMPARTMENT_ID \
  --display-name '${DISPLAY_NAME_PREFIX}VCN' \
  --query 'data[0].id' \
  --raw-output"

if VCN_ID=$(eval "$VCN_ID_CMD"); then
    echo "âœ… VCN ID: $VCN_ID"
    export VCN_ID
    echo ""
else
    echo "âŒ Failed to retrieve VCN ID"
    exit 1
fi

# Step 3: Create subnet
echo "ðŸ”— Step 3: Creating subnet..."
SUBNET_CMD="oci network subnet create \
  --compartment-id $COMPARTMENT_ID \
  --vcn-id $VCN_ID \
  --display-name '${DISPLAY_NAME_PREFIX}Subnet' \
  --cidr-block $SUBNET_CIDR \
  --dns-label kasmsubnet \
  --wait-for-state AVAILABLE"

if ! run_oci_command "$SUBNET_CMD" "Creating subnet"; then
    echo "âš ï¸  Subnet might already exist, continuing..."
fi

# Get subnet ID
echo "ðŸ” Retrieving subnet ID..."
SUBNET_ID_CMD="oci network subnet list \
  --compartment-id $COMPARTMENT_ID \
  --vcn-id $VCN_ID \
  --display-name '${DISPLAY_NAME_PREFIX}Subnet' \
  --query 'data[0].id' \
  --raw-output"

if SUBNET_ID=$(eval "$SUBNET_ID_CMD"); then
    echo "âœ… Subnet ID: $SUBNET_ID"
    export SUBNET_ID
    echo ""
else
    echo "âŒ Failed to retrieve subnet ID"
    exit 1
fi

# Step 4: Create Internet Gateway
echo "ðŸŒ Step 4: Creating Internet Gateway..."
IG_CMD="oci network internet-gateway create \
  --compartment-id $COMPARTMENT_ID \
  --vcn-id $VCN_ID \
  --display-name '${DISPLAY_NAME_PREFIX}IG' \
  --is-enabled true \
  --wait-for-state AVAILABLE"

if ! run_oci_command "$IG_CMD" "Creating Internet Gateway"; then
    echo "âš ï¸  Internet Gateway might already exist, continuing..."
fi

# Get Internet Gateway ID
echo "ðŸ” Retrieving Internet Gateway ID..."
IG_ID_CMD="oci network internet-gateway list \
  --compartment-id $COMPARTMENT_ID \
  --vcn-id $VCN_ID \
  --display-name '${DISPLAY_NAME_PREFIX}IG' \
  --query 'data[0].id' \
  --raw-output"

if IG_ID=$(eval "$IG_ID_CMD"); then
    echo "âœ… Internet Gateway ID: $IG_ID"
    export IG_ID
    echo ""
else
    echo "âŒ Failed to retrieve Internet Gateway ID"
    exit 1
fi

# Step 5: Configure routing
echo "ðŸ›£ï¸  Step 5: Configuring default route..."
RT_ID_CMD="oci network route-table list \
  --compartment-id $COMPARTMENT_ID \
  --vcn-id $VCN_ID \
  --query 'data[?\"is-default\"==true].id | [0]' \
  --raw-output"

if RT_ID=$(eval "$RT_ID_CMD"); then
    echo "âœ… Route Table ID: $RT_ID"
    export RT_ID
    
    # Update route table with default route
    ROUTE_CMD="oci network route-table update \
      --rt-id $RT_ID \
      --route-rules '[{\"destination\":\"0.0.0.0/0\",\"destinationType\":\"CIDR_BLOCK\",\"networkEntityId\":\"'$IG_ID'\"}]' \
      --force"
    
    run_oci_command "$ROUTE_CMD" "Adding default route to Internet Gateway"
else
    echo "âŒ Failed to retrieve Route Table ID"
    exit 1
fi

# Step 6: Create security list for server
echo "ðŸ”’ Step 6: Creating security list for $SERVER_DESCRIPTION..."
SEC_LIST_CMD="oci network security-list create \
  --compartment-id $COMPARTMENT_ID \
  --vcn-id $VCN_ID \
  --display-name '${DISPLAY_NAME_PREFIX}SecList' \
  --ingress-security-rules '$SECURITY_PORTS' \
  --egress-security-rules '[{\"protocol\":\"all\",\"destination\":\"0.0.0.0/0\",\"isStateless\":false}]' \
  --wait-for-state AVAILABLE"

if ! run_oci_command "$SEC_LIST_CMD" "Creating $SERVER_DESCRIPTION security list"; then
    echo "âš ï¸  Security list might already exist, continuing..."
fi

# Get security list ID
echo "ðŸ” Retrieving security list ID..."
SEC_LIST_ID_CMD="oci network security-list list \
  --compartment-id $COMPARTMENT_ID \
  --vcn-id $VCN_ID \
  --display-name '${DISPLAY_NAME_PREFIX}SecList' \
  --query 'data[0].id' \
  --raw-output"

if SEC_LIST_ID=$(eval "$SEC_LIST_ID_CMD"); then
    echo "âœ… Security List ID: $SEC_LIST_ID"
    export SEC_LIST_ID
    
    # Associate security list with subnet
    SUBNET_UPDATE_CMD="oci network subnet update \
      --subnet-id $SUBNET_ID \
      --security-list-ids '[\"'$SEC_LIST_ID'\"]' \
      --force"
    
    run_oci_command "$SUBNET_UPDATE_CMD" "Associating security list with subnet"
else
    echo "âŒ Failed to retrieve security list ID"
    exit 1
fi

# Step 7: Get latest Ubuntu 22.04 ARM64 image
echo "ðŸ’¿ Step 7: Finding latest Ubuntu 22.04 ARM64 image..."
IMAGE_ID_CMD="oci compute image list \
  --compartment-id $TENANCY_OCID \
  --operating-system '$OPERATING_SYSTEM' \
  --operating-system-version '$OPERATING_SYSTEM_VERSION' \
  --sort-by TIMECREATED \
  --sort-order DESC \
  --limit 1 \
  --query 'data[0].id' \
  --raw-output"

if IMAGE_ID=$(eval "$IMAGE_ID_CMD"); then
    echo "âœ… Ubuntu Image ID: $IMAGE_ID"
    export IMAGE_ID
    echo ""
else
    echo "âŒ Failed to retrieve Ubuntu image ID"
    exit 1
fi

# Step 8: Get availability domain
echo "ðŸ¢ Step 8: Getting availability domain..."
AD_CMD="oci iam availability-domain list \
  --compartment-id $COMPARTMENT_ID \
  --query 'data[0].name' \
  --raw-output"

if AVAILABILITY_DOMAIN=$(eval "$AD_CMD"); then
    echo "âœ… Availability Domain: $AVAILABILITY_DOMAIN"
    export AVAILABILITY_DOMAIN
    echo ""
else
    echo "âŒ Failed to retrieve availability domain"
    exit 1
fi

# Step 9: Launch compute instance
echo "ðŸ–¥ï¸  Step 9: Launching compute instance..."
echo "   Shape: $INSTANCE_SHAPE"
echo "   OCPUs: $INSTANCE_OCPUS"
echo "   Memory: ${INSTANCE_MEMORY_GB}GB"
echo "   OS: $OPERATING_SYSTEM $OPERATING_SYSTEM_VERSION"
echo ""

INSTANCE_CMD="oci compute instance launch \
  --compartment-id $COMPARTMENT_ID \
  --availability-domain '$AVAILABILITY_DOMAIN' \
  --shape $INSTANCE_SHAPE \
  --shape-config '{\"ocpus\":$INSTANCE_OCPUS,\"memoryInGBs\":$INSTANCE_MEMORY_GB}' \
  --subnet-id $SUBNET_ID \
  --assign-public-ip true \
  --image-id $IMAGE_ID \
  --ssh-authorized-keys-file $SSH_KEY_PATH \
  --display-name '${DISPLAY_NAME_PREFIX}Instance' \
  --wait-for-state RUNNING"

if ! run_oci_command "$INSTANCE_CMD" "Launching compute instance"; then
    exit 1
fi

# Get instance ID
echo "ðŸ” Retrieving instance ID..."
INSTANCE_ID_CMD="oci compute instance list \
  --compartment-id $COMPARTMENT_ID \
  --display-name '${DISPLAY_NAME_PREFIX}Instance' \
  --query 'data[0].id' \
  --raw-output"

if INSTANCE_ID=$(eval "$INSTANCE_ID_CMD"); then
    echo "âœ… Instance ID: $INSTANCE_ID"
    export INSTANCE_ID
    echo ""
else
    echo "âŒ Failed to retrieve instance ID"
    exit 1
fi

# Step 10: Get instance network details
echo "ðŸŒ Step 10: Retrieving instance network details..."
PUBLIC_IP_CMD="oci compute instance list-vnics \
  --instance-id $INSTANCE_ID \
  --query 'data[0].\"public-ip\"' \
  --raw-output"

PRIVATE_IP_CMD="oci compute instance list-vnics \
  --instance-id $INSTANCE_ID \
  --query 'data[0].\"private-ip\"' \
  --raw-output"

if PUBLIC_IP=$(eval "$PUBLIC_IP_CMD") && PRIVATE_IP=$(eval "$PRIVATE_IP_CMD"); then
    echo "âœ… Public IP: $PUBLIC_IP"
    echo "âœ… Private IP: $PRIVATE_IP"
    export PUBLIC_IP
    export PRIVATE_IP
    echo ""
else
    echo "âŒ Failed to retrieve instance IP addresses"
    exit 1
fi

# Step 11: Verify instance configuration
echo "ðŸ“Š Step 11: Verifying instance configuration..."
INSTANCE_INFO_CMD="oci compute instance get --instance-id $INSTANCE_ID \
  --query 'data.{Name:\"display-name\",State:\"lifecycle-state\",Shape:shape,OCPUs:\"shape-config\".ocpus,Memory:\"shape-config\".\"memory-in-gbs\"}' \
  --output table"

run_oci_command "$INSTANCE_INFO_CMD" "Getting instance configuration" true

# Step 12: Test SSH connectivity
echo "ðŸ”‘ Step 12: Testing SSH connectivity..."
echo "Waiting 60 seconds for instance to be fully ready..."
sleep 60

SSH_TEST_CMD="ssh -i ${SSH_KEY_PATH%.*} -o StrictHostKeyChecking=no -o ConnectTimeout=30 ubuntu@$PUBLIC_IP \
  'echo \"SSH connection successful\" && echo \"System info:\" && uname -a && echo \"Memory:\" && free -h && echo \"CPUs:\" && nproc'"

if run_oci_command "$SSH_TEST_CMD" "Testing SSH connectivity" true; then
    echo "ðŸŽ‰ SSH connectivity verified!"
else
    echo "âš ï¸  SSH test failed, but instance may still be starting up"
fi

# Step 13: Save configuration to .env file
echo "ðŸ’¾ Step 13: Saving configuration to .env file..."
cat >> "$SCRIPT_DIR/.env" << EOF

# Generated OCI Infrastructure IDs ($(date))
COMPARTMENT_ID=$COMPARTMENT_ID
VCN_ID=$VCN_ID
SUBNET_ID=$SUBNET_ID
INTERNET_GATEWAY_ID=$IG_ID
ROUTE_TABLE_ID=$RT_ID
SECURITY_LIST_ID=$SEC_LIST_ID
INSTANCE_ID=$INSTANCE_ID
AVAILABILITY_DOMAIN=$AVAILABILITY_DOMAIN
UBUNTU_IMAGE_ID=$IMAGE_ID

# Instance Network Details
INSTANCE_PUBLIC_IP=$PUBLIC_IP
INSTANCE_PRIVATE_IP=$PRIVATE_IP

# Update server IP for other scripts
EOF

# Add server-specific IP variable
if [ "$SERVER_TYPE" = "kasm" ]; then
    echo "KASM_SERVER_IP=$PUBLIC_IP" >> "$SCRIPT_DIR/.env"
elif [ "$SERVER_TYPE" = "coolify" ]; then
    echo "COOLIFY_SERVER_IP=$PUBLIC_IP" >> "$SCRIPT_DIR/.env"
fi

echo "âœ… Configuration saved to .env file"
echo ""

# Final summary
echo "ðŸŽ‰ OCI Infrastructure Setup Completed Successfully!"
echo ""
echo "ðŸ“‹ Infrastructure Summary:"
echo "   Server Type: $SERVER_TYPE ($SERVER_DESCRIPTION)"
echo "   Compartment: $COMPARTMENT_NAME ($COMPARTMENT_ID)"
echo "   VCN: ${DISPLAY_NAME_PREFIX}VCN ($VCN_ID)"
echo "   Subnet: ${DISPLAY_NAME_PREFIX}Subnet ($SUBNET_ID)"
echo "   Internet Gateway: ${DISPLAY_NAME_PREFIX}IG ($IG_ID)"
echo "   Security List: ${DISPLAY_NAME_PREFIX}SecList ($SEC_LIST_ID)"
echo "   Instance: ${DISPLAY_NAME_PREFIX}Instance ($INSTANCE_ID)"
echo ""
echo "ðŸŒ Network Configuration:"
echo "   Public IP: $PUBLIC_IP"
echo "   Private IP: $PRIVATE_IP"
echo "   SSH Access: ssh -i ${SSH_KEY_PATH%.*} ubuntu@$PUBLIC_IP"
echo ""
echo "ðŸ”’ Security Configuration:"
echo "   SSH (22): âœ… Open"
if [ "$SERVER_TYPE" = "kasm" ]; then
    echo "   KASM Web (8443): âœ… Open"
    echo "   RDP (3389): âœ… Open"
    echo "   Session Ports (3000-4000): âœ… Open"
elif [ "$SERVER_TYPE" = "coolify" ]; then
    echo "   Coolify Web (8000): âœ… Open"
    echo "   HTTP (80): âœ… Open"
    echo "   HTTPS (443): âœ… Open"
    echo "   Proxy HTTP (6001): âœ… Open"
    echo "   Proxy HTTPS (6002): âœ… Open"
fi
echo ""
echo "ðŸ”§ Instance Specifications:"
echo "   Shape: $INSTANCE_SHAPE"
echo "   OCPUs: $INSTANCE_OCPUS"
echo "   Memory: ${INSTANCE_MEMORY_GB}GB"
echo "   OS: $OPERATING_SYSTEM $OPERATING_SYSTEM_VERSION"
echo "   Architecture: ARM64 (Ampere)"
echo ""
if [ "$SERVER_TYPE" = "kasm" ]; then
    echo "âœ… Ready for KASM installation (run kasm-installation.sh)"
    echo "âœ… Ready for Cloudflare tunnel setup (run cloudflare-tunnel-setup.sh)"
elif [ "$SERVER_TYPE" = "coolify" ]; then
    echo "âœ… Ready for Coolify installation (run coolify/coolify-installation.sh)"
    echo "âœ… Ready for Cloudflare tunnel setup (run coolify/coolify-cloudflare-tunnel-setup.sh)"
fi
