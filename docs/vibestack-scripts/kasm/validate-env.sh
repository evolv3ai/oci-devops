#!/bin/bash
# Environment Validation Script for KASM
# This is a wrapper that calls the centralized validation script
# Located in the /oci folder for DRY principle compliance

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OCI_DIR="$(cd "$SCRIPT_DIR/../oci" && pwd)"

# Colors for output
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}🔍 KASM Environment Validation (using centralized OCI scripts)${NC}"
echo "=============================================================="
echo ""

# Check if centralized script exists
if [ ! -f "$OCI_DIR/validate-env.sh" ]; then
    echo -e "${RED}❌ Error: Centralized validation script not found at $OCI_DIR/validate-env.sh${NC}"
    exit 1
fi

# Call the centralized validation script with 'kasm' parameter
bash "$OCI_DIR/validate-env.sh" kasm

# The centralized script will handle all validation and exit codes

# Source the .env file
source "$SCRIPT_DIR/.env"

echo -e "${CYAN}📋 Validating required environment variables...${NC}"
echo ""

# Define required variables for different components
OCI_REQUIRED_VARS=(
    "TENANCY_OCID"
    "REGION"
    "COMPARTMENT_NAME"
    "VCN_CIDR"
    "SUBNET_CIDR"
    "DISPLAY_NAME_PREFIX"
    "SSH_KEY_PATH"
    "INSTANCE_SHAPE"
    "INSTANCE_OCPUS"
    "INSTANCE_MEMORY_GB"
    "OPERATING_SYSTEM"
    "OPERATING_SYSTEM_VERSION"
)

# Server-specific required variables
if [ "$SERVER_TYPE" = "kasm" ]; then
    SERVER_REQUIRED_VARS=(
        "KASM_SERVER_IP"
        "SSH_USER"
        "SSH_KEY_PATH"
        "KASM_PORT"
        "RDP_PORT"
    )
    SERVER_NAME="KASM Installation"
elif [ "$SERVER_TYPE" = "coolify" ]; then
    SERVER_REQUIRED_VARS=(
        "COOLIFY_SERVER_IP"
        "SSH_USER"
        "SSH_KEY_PATH"
        "COOLIFY_PORT"
        "ROOT_USERNAME"
        "ROOT_USER_EMAIL"
        "ROOT_USER_PASSWORD"
    )
    SERVER_NAME="Coolify Installation"
else
    echo -e "${RED}❌ Unknown server type: $SERVER_TYPE${NC}"
    echo "Usage: $0 [kasm|coolify]"
    exit 1
fi

CLOUDFLARE_REQUIRED_VARS=(
    "CLOUDFLARE_API_TOKEN"
    "CLOUDFLARE_ACCOUNT_ID"
    "TUNNEL_NAME"
    "TUNNEL_HOSTNAME"
)

# Function to validate a set of variables
validate_vars() {
    local var_group_name="$1"
    shift
    local vars=("$@")
    local missing_vars=()
    local has_values=true
    
    echo -e "${YELLOW}Checking $var_group_name variables:${NC}"
    
    for var in "${vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
            echo -e "  ${RED}✗${NC} $var: ${RED}NOT SET${NC}"
            has_values=false
        else
            # Mask sensitive values
            if [[ "$var" == *"TOKEN"* ]] || [[ "$var" == *"KEY"* ]] || [[ "$var" == *"PASSWORD"* ]]; then
                echo -e "  ${GREEN}✓${NC} $var: ${GREEN}[REDACTED]${NC}"
            elif [[ "$var" == *"OCID"* ]]; then
                # Show partial OCID
                value="${!var}"
                if [ ${#value} -gt 20 ]; then
                    echo -e "  ${GREEN}✓${NC} $var: ${GREEN}${value:0:20}...${NC}"
                else
                    echo -e "  ${GREEN}✓${NC} $var: ${GREEN}SET${NC}"
                fi
            else
                echo -e "  ${GREEN}✓${NC} $var: ${GREEN}${!var}${NC}"
            fi
        fi
    done
    
    echo ""
    return $([ "$has_values" = true ] && echo 0 || echo 1)
}

# Track overall validation status
VALIDATION_FAILED=false

# Validate OCI variables
if ! validate_vars "OCI Infrastructure" "${OCI_REQUIRED_VARS[@]}"; then
    VALIDATION_FAILED=true
fi

# Check server-specific variables
if [ "$SERVER_TYPE" = "kasm" ]; then
    if [ -n "$KASM_SERVER_IP" ] || [ "$2" == "--force" ]; then
        if ! validate_vars "$SERVER_NAME" "${SERVER_REQUIRED_VARS[@]}"; then
            if [ "$2" != "--skip-server" ]; then
                echo -e "${YELLOW}Note: KASM_SERVER_IP will be set after OCI infrastructure setup${NC}"
                echo ""
            fi
        fi
    fi
elif [ "$SERVER_TYPE" = "coolify" ]; then
    if [ -n "$COOLIFY_SERVER_IP" ] || [ "$2" == "--force" ]; then
        if ! validate_vars "$SERVER_NAME" "${SERVER_REQUIRED_VARS[@]}"; then
            if [ "$2" != "--skip-server" ]; then
                echo -e "${YELLOW}Note: COOLIFY_SERVER_IP will be set after OCI infrastructure setup${NC}"
                echo ""
            fi
        fi
    fi
fi

# Validate Cloudflare variables
if ! validate_vars "Cloudflare Tunnel" "${CLOUDFLARE_REQUIRED_VARS[@]}"; then
    VALIDATION_FAILED=true
fi

# Additional file checks
echo -e "${CYAN}📁 Checking required files:${NC}"

# Check SSH key file exists
if [ -n "$SSH_KEY_PATH" ]; then
    if [ -f "$SSH_KEY_PATH" ]; then
        echo -e "  ${GREEN}✓${NC} SSH public key: $SSH_KEY_PATH"
        
        # Check permissions
        if [ -f "${SSH_KEY_PATH%.pub}" ]; then
            perms=$(stat -c %a "${SSH_KEY_PATH%.pub}" 2>/dev/null || stat -f %A "${SSH_KEY_PATH%.pub}" 2>/dev/null || echo "unknown")
            if [ "$perms" != "600" ] && [ "$perms" != "unknown" ]; then
                echo -e "  ${YELLOW}⚠️  SSH private key permissions should be 600, found: $perms${NC}"
            fi
        fi
    else
        echo -e "  ${RED}✗${NC} SSH public key not found: $SSH_KEY_PATH"
        VALIDATION_FAILED=true
    fi
else
    echo -e "  ${RED}✗${NC} SSH_KEY_PATH not set"
    VALIDATION_FAILED=true
fi

echo ""

# Check OCI CLI installation
echo -e "${CYAN}🔧 Checking OCI CLI:${NC}"
if command -v oci >/dev/null 2>&1; then
    OCI_VERSION=$(oci --version 2>/dev/null || echo "unknown")
    echo -e "  ${GREEN}✓${NC} OCI CLI installed: $OCI_VERSION"
    
    # Check OCI config
    OCI_CONFIG="${HOME}/.oci/config"
    if [ -f "$OCI_CONFIG" ]; then
        echo -e "  ${GREEN}✓${NC} OCI config found: $OCI_CONFIG"
    else
        echo -e "  ${YELLOW}⚠️  OCI config not found. Run: oci setup config${NC}"
    fi
else
    echo -e "  ${RED}✗${NC} OCI CLI not installed"
    echo -e "  ${YELLOW}Run: bash $SCRIPT_DIR/preflight-check.sh${NC}"
    VALIDATION_FAILED=true
fi

echo ""

# Summary
echo "=========================================="
if [ "$VALIDATION_FAILED" = true ]; then
    echo -e "${RED}❌ Validation Failed${NC}"
    echo ""
    echo "Please set the missing environment variables in:"
    echo -e "  ${CYAN}$SCRIPT_DIR/.env${NC}"
    echo ""
    echo "For OCI setup, you'll need:"
    echo "  1. An Oracle Cloud account"
    echo "  2. OCI CLI configured (run: oci setup config)"
    echo "  3. SSH key pair generated"
    echo ""
    echo "For Cloudflare tunnel, you'll need:"
    echo "  1. A Cloudflare account"
    echo "  2. API token with Zone:Edit and Account:Cloudflare Tunnel:Edit permissions"
    echo "  3. A domain managed by Cloudflare"
    echo ""
    exit 1
else
    echo -e "${GREEN}✅ All validations passed!${NC}"
    echo ""
    echo "Ready to proceed with:"
    echo "  1. OCI infrastructure provisioning"
    if [ "$SERVER_TYPE" = "kasm" ]; then
        echo "  2. KASM Workspaces installation"
        echo "  3. Cloudflare tunnel setup"
        echo ""
        echo "Next steps:"
        echo -e "  ${CYAN}bash $SCRIPT_DIR/oci-infrastructure-setup.sh kasm${NC}"
        echo -e "  ${CYAN}bash $SCRIPT_DIR/kasm-installation.sh${NC}"
        echo -e "  ${CYAN}bash $SCRIPT_DIR/cloudflare-tunnel-setup.sh${NC}"
    elif [ "$SERVER_TYPE" = "coolify" ]; then
        echo "  2. Coolify installation"
        echo "  3. Cloudflare tunnel setup"
        echo ""
        echo "Next steps:"
        echo -e "  ${CYAN}bash $SCRIPT_DIR/oci-infrastructure-setup.sh coolify${NC}"
        echo -e "  ${CYAN}bash $SCRIPT_DIR/../coolify/coolify-installation.sh${NC}"
        echo -e "  ${CYAN}bash $SCRIPT_DIR/../coolify/coolify-cloudflare-tunnel-setup.sh${NC}"
    fi
    echo ""
    exit 0
fi