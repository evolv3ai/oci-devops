#!/bin/bash
# Universal OCI Terraform Setup for Semaphore
# Combines best practices from all testing approaches
# Version: 1.0.0

set -e

echo "================================================"
echo "Universal OCI Terraform Setup for Semaphore"
echo "Version: 1.0.0"
echo "================================================"
echo ""

# ===========================
# 1. ENVIRONMENT DETECTION
# ===========================
echo "[1/7] Detecting environment..."

if [ -f /.dockerenv ] || [ -n "$SEMAPHORE_PROJECT_ID" ]; then
    echo "✓ Running in Semaphore container environment"
    IN_CONTAINER=true
else
    echo "ℹ Running in local environment"
    IN_CONTAINER=false
fi
echo ""

# ===========================
# 2. CONFIGURATION SETUP
# ===========================
echo "[2/7] Setting up OCI configuration..."

# Priority order for config file location
CONFIG_LOCATIONS=(
    "/home/semaphore/.oci/config"     # Semaphore standard
    "/oci/config"                     # Docker volume mount
    "$HOME/.oci/config"               # Local environment
)

OCI_CONFIG_FOUND=""
for config_path in "${CONFIG_LOCATIONS[@]}"; do
    if [ -f "$config_path" ]; then
        OCI_CONFIG_FOUND="$config_path"
        echo "✓ Found OCI config at: $config_path"
        break
    fi
done

if [ -z "$OCI_CONFIG_FOUND" ]; then
    echo "❌ ERROR: No OCI configuration file found!"
    echo "   Searched locations:"
    for loc in "${CONFIG_LOCATIONS[@]}"; do
        echo "   - $loc"
    done
    echo ""
    echo "   Please ensure OCI credentials are properly configured:"
    echo "   1. Mount ~/.oci folder in docker-compose.yml"
    echo "   2. Or store config in Semaphore Key Store"
    exit 1
fi

export OCI_CLI_CONFIG_FILE="$OCI_CONFIG_FOUND"
echo ""
# ===========================
# 3. PATH FIXING
# ===========================
echo "[3/7] Fixing configuration paths..."

# Create working copy to avoid modifying mounted read-only files
cp "$OCI_CLI_CONFIG_FILE" /tmp/oci_config_working

# Fix various path formats
echo "  - Converting Windows paths..."
sed -i 's|C:\\Users\\[^\\]*\\.oci\\|/home/semaphore/.oci/|g' /tmp/oci_config_working
sed -i 's|C:\\Users\\[^\\]*\\.oci/|/home/semaphore/.oci/|g' /tmp/oci_config_working

echo "  - Converting Unix home paths..."
sed -i 's|~/.oci/|/home/semaphore/.oci/|g' /tmp/oci_config_working
sed -i 's|/Users/[^/]*/.oci/|/home/semaphore/.oci/|g' /tmp/oci_config_working

echo "  - Fixing path separators..."
sed -i 's|\\|/|g' /tmp/oci_config_working

# Use the fixed config
export OCI_CLI_CONFIG_FILE="/tmp/oci_config_working"
echo "✓ Configuration paths fixed"
echo ""

# ===========================
# 4. PROFILE MANAGEMENT
# ===========================
echo "[4/7] Managing OCI profiles..."

# Determine which profile to use
if [ -n "$OCI_CONFIG_PROFILE" ]; then
    PROFILE="$OCI_CONFIG_PROFILE"
    echo "  Using specified profile: $PROFILE"
elif [ -n "$oci_profile" ]; then
    PROFILE="$oci_profile"
    echo "  Using profile from oci_profile variable: $PROFILE"
elif [ -n "$TF_VAR_config_file_profile" ]; then
    PROFILE="$TF_VAR_config_file_profile"
    echo "  Using profile from TF_VAR: $PROFILE"
else
    PROFILE="DEFAULT"
    echo "  No profile specified, using: DEFAULT"
fi

# Check if profile exists
if ! grep -q "\[$PROFILE\]" "$OCI_CLI_CONFIG_FILE"; then
    echo "  ⚠️ Profile '$PROFILE' not found"
    
    # Try to create from DEFAULT if it exists
    if grep -q "\[DEFAULT\]" "$OCI_CLI_CONFIG_FILE"; then
        echo "  Creating '$PROFILE' from DEFAULT profile..."
        
        # Extract DEFAULT profile values
        DEFAULT_USER=$(grep -A10 "^\[DEFAULT\]" "$OCI_CLI_CONFIG_FILE" | grep "^user" | head -1 | cut -d'=' -f2 | tr -d ' ')
        DEFAULT_TENANCY=$(grep -A10 "^\[DEFAULT\]" "$OCI_CLI_CONFIG_FILE" | grep "^tenancy" | head -1 | cut -d'=' -f2 | tr -d ' ')
        DEFAULT_REGION=$(grep -A10 "^\[DEFAULT\]" "$OCI_CLI_CONFIG_FILE" | grep "^region" | head -1 | cut -d'=' -f2 | tr -d ' ')
        DEFAULT_FINGERPRINT=$(grep -A10 "^\[DEFAULT\]" "$OCI_CLI_CONFIG_FILE" | grep "^fingerprint" | head -1 | cut -d'=' -f2 | tr -d ' ')
        DEFAULT_KEY=$(grep -A10 "^\[DEFAULT\]" "$OCI_CLI_CONFIG_FILE" | grep "^key_file" | head -1 | cut -d'=' -f2 | tr -d ' ')
        
        # Append new profile
        {
            echo ""
            echo "[$PROFILE]"
            [ -n "$DEFAULT_USER" ] && echo "user=$DEFAULT_USER"
            [ -n "$DEFAULT_FINGERPRINT" ] && echo "fingerprint=$DEFAULT_FINGERPRINT"
            [ -n "$DEFAULT_KEY" ] && echo "key_file=$DEFAULT_KEY"
            [ -n "$DEFAULT_TENANCY" ] && echo "tenancy=$DEFAULT_TENANCY"
            [ -n "$DEFAULT_REGION" ] && echo "region=${DEFAULT_REGION:-us-ashburn-1}"
        } >> "$OCI_CLI_CONFIG_FILE"
        
        echo "  ✓ Profile '$PROFILE' created"
    else
        echo "  ❌ ERROR: Cannot create profile - no DEFAULT profile found"
        exit 1
    fi
else
    echo "  ✓ Profile '$PROFILE' exists"
fi

export TF_VAR_config_file_profile="$PROFILE"
echo ""
# ===========================
# 5. KEY VALIDATION & FIXING
# ===========================
echo "[5/7] Validating private keys..."

# Get key file path from the profile
PROFILE_KEY=$(grep -A10 "^\[$PROFILE\]" "$OCI_CLI_CONFIG_FILE" | grep "^key_file" | head -1 | cut -d'=' -f2 | tr -d ' ')

if [ -n "$PROFILE_KEY" ]; then
    echo "  Profile key path: $PROFILE_KEY"
    
    # Check if key exists at specified location
    if [ ! -f "$PROFILE_KEY" ]; then
        echo "  ⚠️ Key not found at configured path"
        echo "  Searching for private key..."
        
        # Common key locations to check
        KEY_LOCATIONS=(
            "/home/semaphore/.oci/oci_api_key.pem"
            "/home/semaphore/.oci/key.pem"
            "/home/semaphore/.oci/private_key.pem"
            "/oci/oci_api_key.pem"
            "/oci/key.pem"
            "/oci/private_key.pem"
            "$HOME/.oci/oci_api_key.pem"
            "$HOME/.oci/key.pem"
        )
        
        FOUND_KEY=""
        for key_path in "${KEY_LOCATIONS[@]}"; do
            if [ -f "$key_path" ]; then
                echo "  ✓ Found private key at: $key_path"
                FOUND_KEY="$key_path"
                break
            fi
        done
        
        if [ -n "$FOUND_KEY" ]; then
            echo "  Updating config to use found key..."
            sed -i "/^\[$PROFILE\]/,/^\[/ s|^key_file=.*|key_file=$FOUND_KEY|" "$OCI_CLI_CONFIG_FILE"
            PROFILE_KEY="$FOUND_KEY"
        else
            echo "  ❌ ERROR: No private key found in any expected location!"
            echo "     Searched locations:"
            for loc in "${KEY_LOCATIONS[@]}"; do
                echo "     - $loc"
            done
            exit 1
        fi
    fi
    
    # Set proper permissions
    chmod 600 "$PROFILE_KEY" 2>/dev/null || true
    echo "  ✓ Private key validated: $PROFILE_KEY"
else
    echo "  ❌ ERROR: No key_file specified in profile '$PROFILE'"
    exit 1
fi
echo ""
# ===========================
# 6. REQUIRED FIELDS VALIDATION
# ===========================
echo "[6/7] Validating required OCI fields..."

MISSING_FIELDS=()
REQUIRED_FIELDS=("user" "fingerprint" "key_file" "tenancy" "region")

for field in "${REQUIRED_FIELDS[@]}"; do
    VALUE=$(grep -A10 "^\[$PROFILE\]" "$OCI_CLI_CONFIG_FILE" | grep "^${field}=" | head -1 | cut -d'=' -f2 | tr -d ' ')
    if [ -n "$VALUE" ]; then
        echo "  ✓ ${field}: configured"
    else
        echo "  ✗ ${field}: missing"
        MISSING_FIELDS+=("$field")
    fi
done

if [ ${#MISSING_FIELDS[@]} -gt 0 ]; then
    echo ""
    echo "  ❌ ERROR: Missing required fields in profile '$PROFILE':"
    echo "     ${MISSING_FIELDS[*]}"
    echo ""
    echo "  Please ensure your OCI config contains all required fields."
    exit 1
fi
echo ""

# ===========================
# 7. EXPORT ENVIRONMENT
# ===========================
echo "[7/7] Setting up environment variables..."

# Export OCI CLI config
echo "  OCI_CLI_CONFIG_FILE=$OCI_CLI_CONFIG_FILE"

# Export Terraform variables if needed
if [ -n "$TF_VAR_compartment_id" ]; then
    echo "  TF_VAR_compartment_id=$TF_VAR_compartment_id"
elif [ -n "$compartment_id" ]; then
    export TF_VAR_compartment_id="$compartment_id"
    echo "  TF_VAR_compartment_id=$TF_VAR_compartment_id (from compartment_id)"
fi

if [ -n "$TF_VAR_region" ]; then
    echo "  TF_VAR_region=$TF_VAR_region"
elif [ -n "$region" ]; then
    export TF_VAR_region="$region"
    echo "  TF_VAR_region=$TF_VAR_region (from region)"
fi

echo ""
echo "================================================"
echo "✅ OCI Environment Setup Complete!"
echo "================================================"
echo ""
echo "Profile: $PROFILE"
echo "Config:  $OCI_CLI_CONFIG_FILE"
echo ""
echo "You can now run Terraform commands:"
echo "  terraform init"
echo "  terraform plan"
echo "  terraform apply"
echo ""

# Return success
exit 0
