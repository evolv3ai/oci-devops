#!/bin/bash
# Environment Validation Script for DevOps Mode (Centralized)
# Ensures all required environment variables are set before provisioning
# Supports both KASM and Coolify deployments

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get server type from command line argument or from DEPLOYMENT_TYPE
SERVER_TYPE="${1:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🔍 Environment Validation for DevOps Mode${NC}"
echo "=========================================="
echo ""

# Check if .env exists
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${YELLOW}⚠️  .env file not found${NC}"
    
    if [ -f "$SCRIPT_DIR/.env.example" ]; then
        echo -e "${CYAN}Creating .env from template...${NC}"
        cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
        echo -e "${GREEN}✅ Created .env from .env.example${NC}"
        echo ""
        echo -e "${YELLOW}📝 Please edit the following file with your values:${NC}"
        echo -e "   ${CYAN}$SCRIPT_DIR/.env${NC}"
        echo ""
        echo "Required variables to configure:"
        echo "  - DEPLOYMENT_TYPE: Choose kasm, coolify, both, or none"
        echo "  - TENANCY_OCID: Your OCI tenancy OCID"
        echo "  - REGION: OCI region (e.g., us-ashburn-1)"
        echo "  - COMPARTMENT_NAME: Name for the OCI compartment"
        echo "  - SSH_KEY_PATH: Path to your SSH public key"
        echo "  - CLOUDFLARE_API_TOKEN: Your Cloudflare API token"
        echo "  - CLOUDFLARE_ACCOUNT_ID: Your Cloudflare account ID"
        echo "  - TUNNEL_HOSTNAME: Domain for Cloudflare tunnel"
        echo ""
        exit 1
    else
        echo -e "${RED}❌ No .env.example file found${NC}"
        echo "Please create a .env file with the required configuration"
        exit 1
    fi
fi

# Source the .env file
source "$SCRIPT_DIR/.env"

# Determine server type from DEPLOYMENT_TYPE if not specified
if [ -z "$SERVER_TYPE" ]; then
    case "$DEPLOYMENT_TYPE" in
        kasm)
            SERVER_TYPE="kasm"
            ;;
        coolify)
            SERVER_TYPE="coolify"
            ;;
        both)
            echo -e "${CYAN}📋 DEPLOYMENT_TYPE is set to 'both'${NC}"
            echo "Validating configuration for both KASM and Coolify..."
            SERVER_TYPE="both"
            ;;
        none)
            echo -e "${YELLOW}⚠️  DEPLOYMENT_TYPE is set to 'none'${NC}"
            echo "No server deployment configured."
            exit 0
            ;;
        *)
            echo -e "${YELLOW}⚠️  DEPLOYMENT_TYPE not set or invalid${NC}"
            echo "Please set DEPLOYMENT_TYPE to: kasm, coolify, both, or none"
            exit 1
            ;;
    esac
fi

echo -e "${CYAN}📋 Validating configuration for: $SERVER_TYPE${NC}"
echo ""

# Define required variables for different components
OCI_REQUIRED_VARS=(
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

# Check server-specific variables based on deployment type
if [ "$SERVER_TYPE" = "kasm" ] || [ "$SERVER_TYPE" = "both" ]; then
    KASM_VARS=(
        "KASM_OCPUS"
        "KASM_MEMORY_GB"
        "KASM_STORAGE_GB"
        "KASM_PREFIX"
        "KASM_PORT"
        "RDP_PORT"
    )
    
    echo -e "${CYAN}KASM-specific configuration:${NC}"
    if ! validate_vars "KASM Resources" "${KASM_VARS[@]}"; then
        echo -e "${YELLOW}Note: Using default KASM resource values${NC}"
    fi
fi

if [ "$SERVER_TYPE" = "coolify" ] || [ "$SERVER_TYPE" = "both" ]; then
    COOLIFY_VARS=(
        "COOLIFY_OCPUS"
        "COOLIFY_MEMORY_GB"
        "COOLIFY_STORAGE_GB"
        "COOLIFY_PREFIX"
        "COOLIFY_PORT"
        "ROOT_USERNAME"
        "ROOT_USER_EMAIL"
        "ROOT_USER_PASSWORD"
    )
    
    echo -e "${CYAN}Coolify-specific configuration:${NC}"
    if ! validate_vars "Coolify Resources" "${COOLIFY_VARS[@]}"; then
        echo -e "${YELLOW}Note: Using default Coolify resource values${NC}"
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
        
        # Check for private key
        PRIVATE_KEY="${SSH_KEY_PATH%.pub}"
        if [ -f "$PRIVATE_KEY" ]; then
            echo -e "  ${GREEN}✓${NC} SSH private key: $PRIVATE_KEY"
            
            # Check permissions on Windows (Git Bash)
            if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
                echo -e "  ${YELLOW}ℹ${NC} Running on Windows - SSH key permissions not checked"
            else
                perms=$(stat -c %a "$PRIVATE_KEY" 2>/dev/null || stat -f %A "$PRIVATE_KEY" 2>/dev/null || echo "unknown")
                if [ "$perms" != "600" ] && [ "$perms" != "unknown" ]; then
                    echo -e "  ${YELLOW}⚠️  SSH private key permissions should be 600, found: $perms${NC}"
                    echo -e "  ${CYAN}Fix with: chmod 600 $PRIVATE_KEY${NC}"
                fi
            fi
        else
            echo -e "  ${RED}✗${NC} SSH private key not found: $PRIVATE_KEY"
            VALIDATION_FAILED=true
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
    echo -e "  ${YELLOW}Run preflight check to install: bash $SCRIPT_DIR/preflight-check.sh${NC}"
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
    echo "Deployment Type: ${DEPLOYMENT_TYPE}"
    echo ""
    
    case "$DEPLOYMENT_TYPE" in
        kasm)
            echo "Ready to deploy KASM Workspaces:"
            echo -e "  ${CYAN}bash $SCRIPT_DIR/oci-infrastructure-setup.sh kasm${NC}"
            echo -e "  ${CYAN}bash $SCRIPT_DIR/../kasm/kasm-installation.sh${NC}"
            echo -e "  ${CYAN}bash $SCRIPT_DIR/../kasm/cloudflare-tunnel-setup.sh${NC}"
            ;;
        coolify)
            echo "Ready to deploy Coolify:"
            echo -e "  ${CYAN}bash $SCRIPT_DIR/oci-infrastructure-setup.sh coolify${NC}"
            echo -e "  ${CYAN}bash $SCRIPT_DIR/../coolify/coolify-installation.sh${NC}"
            echo -e "  ${CYAN}bash $SCRIPT_DIR/../coolify/coolify-cloudflare-tunnel-setup.sh${NC}"
            ;;
        both)
            echo "Ready to deploy both KASM and Coolify:"
            echo ""
            echo "For KASM:"
            echo -e "  ${CYAN}bash $SCRIPT_DIR/oci-infrastructure-setup.sh kasm${NC}"
            echo -e "  ${CYAN}bash $SCRIPT_DIR/../kasm/kasm-installation.sh${NC}"
            echo -e "  ${CYAN}bash $SCRIPT_DIR/../kasm/cloudflare-tunnel-setup.sh${NC}"
            echo ""
            echo "For Coolify:"
            echo -e "  ${CYAN}bash $SCRIPT_DIR/oci-infrastructure-setup.sh coolify${NC}"
            echo -e "  ${CYAN}bash $SCRIPT_DIR/../coolify/coolify-installation.sh${NC}"
            echo -e "  ${CYAN}bash $SCRIPT_DIR/../coolify/coolify-cloudflare-tunnel-setup.sh${NC}"
            ;;
    esac
    echo ""
    exit 0
fi