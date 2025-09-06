#!/bin/bash
# Test script for OCI Terraform setup
# Run this to validate your configuration

echo "================================"
echo "OCI Terraform Setup Test"
echo "================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Testing: $test_name... "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ PASSED${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 1: Check if setup script exists
run_test "Setup script exists" "[ -f ./scripts/oci-terraform-setup.sh ]"

# Test 2: Check if setup script is executable
if [ -f ./scripts/oci-terraform-setup.sh ]; then
    chmod +x ./scripts/oci-terraform-setup.sh
    run_test "Setup script is executable" "[ -x ./scripts/oci-terraform-setup.sh ]"
fi

# Test 3: Check Docker compose file
run_test "Docker compose file exists" "[ -f ./docker-compose.yml ]"

# Test 4: Check for OCI mount in docker-compose
run_test "OCI mount configured" "grep -q '\.oci:' ./docker-compose.yml"

# Test 5: Check local OCI directory
run_test "Local .oci directory exists" "[ -d ~/.oci ]"

# Test 6: Check OCI config file
run_test "OCI config file exists" "[ -f ~/.oci/config ]"

# Test 7: Check for private key
if [ -f ~/.oci/config ]; then
    KEY_FILE=$(grep "^key_file=" ~/.oci/config | head -1 | cut -d'=' -f2 | tr -d ' ')
    if [ -n "$KEY_FILE" ]; then
        # Expand tilde if present
        KEY_FILE="${KEY_FILE/#\~/$HOME}"
        run_test "OCI private key exists" "[ -f '$KEY_FILE' ]"
    else
        echo -e "Testing: OCI private key exists... ${YELLOW}⚠ SKIPPED${NC} (no key_file in config)"
    fi
fi

# Test 8: Check Terraform installation
run_test "Terraform installed" "which terraform"

# Test 9: Source and test the setup script
echo ""
echo "Running setup script test..."
echo "----------------------------"

# Create a test environment
export TEST_MODE=true

# Try to source the script
if source ./scripts/oci-terraform-setup.sh 2>/dev/null; then
    echo -e "${GREEN}✓ Setup script completed successfully${NC}"
    ((TESTS_PASSED++))
    
    # Test 10: Check if environment variables are set
    run_test "OCI_CLI_CONFIG_FILE is set" "[ -n '$OCI_CLI_CONFIG_FILE' ]"
    run_test "Config file exists at path" "[ -f '$OCI_CLI_CONFIG_FILE' ]"
else
    echo -e "${RED}✗ Setup script failed${NC}"
    ((TESTS_FAILED++))
fi

# Summary
echo ""
echo "================================"
echo "Test Summary"
echo "================================"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! Your setup is ready.${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Update your Semaphore template to use: source ./scripts/oci-terraform-setup.sh"
    echo "2. Run: terraform init"
    echo "3. Run: terraform plan"
    exit 0
else
    echo -e "${YELLOW}⚠️ Some tests failed. Please review the issues above.${NC}"
    echo ""
    echo "Common fixes:"
    echo "- Ensure ~/.oci/config exists with valid OCI credentials"
    echo "- Verify private key file exists and has correct permissions (600)"
    echo "- Check docker-compose.yml has the OCI mount configured"
    echo "- Install Terraform if not present"
    exit 1
fi
