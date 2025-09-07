#!/bin/bash
# Verification Script for Semaphore + Terraform + OCI
# Purpose: Validate authentication and basic resource creation

echo "========================================="
echo "Semaphore OCI Infrastructure Verification"
echo "========================================="
echo ""

# Check if running in Semaphore container
if [ -f /oci/config ]; then
    echo "✅ OCI config file found at /oci/config"
else
    echo "❌ OCI config file NOT found at /oci/config"
    echo "   Please ensure Docker volume is mounted: ~/.oci:/oci:ro"
    exit 1
fi

# Check environment variables
echo ""
echo "Checking environment variables..."
if [ -z "$TF_VAR_compartment_id" ]; then
    echo "❌ TF_VAR_compartment_id not set"
    exit 1
else
    echo "✅ TF_VAR_compartment_id is set"
fi

if [ -z "$TF_VAR_ssh_public_key" ]; then
    echo "❌ TF_VAR_ssh_public_key not set"
    exit 1
else
    echo "✅ TF_VAR_ssh_public_key is set"
fi

# Test OCI CLI
echo ""
echo "Testing OCI CLI authentication..."
oci iam region list --config-file /oci/config 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ OCI CLI authentication successful"
else
    echo "❌ OCI CLI authentication failed"
    exit 1
fi

# Test Terraform
echo ""
echo "Testing Terraform initialization..."
cd /home/semaphore/terraform

# Use test configuration first
if [ -f test-vcn-only.tf ]; then
    echo "Using test-vcn-only.tf for validation..."
    
    # Temporarily move main terraform files
    mkdir -p temp_backup
    mv main.tf variables.tf outputs.tf temp_backup/ 2>/dev/null
    
    # Initialize with test config
    terraform init
    if [ $? -eq 0 ]; then
        echo "✅ Terraform initialization successful"
        
        # Validate configuration
        terraform validate
        if [ $? -eq 0 ]; then
            echo "✅ Terraform configuration is valid"
            
            # Plan to see what would be created
            echo ""
            echo "Running terraform plan..."
            terraform plan -input=false
            if [ $? -eq 0 ]; then
                echo "✅ Terraform plan successful"
                echo ""
                echo "========================================="
                echo "✅ ALL CHECKS PASSED!"
                echo "========================================="
                echo ""
                echo "Ready to create infrastructure with:"
                echo "  terraform apply -auto-approve"
            else
                echo "❌ Terraform plan failed"
                exit 1
            fi
        else
            echo "❌ Terraform validation failed"
            exit 1
        fi
    else
        echo "❌ Terraform initialization failed"
        exit 1
    fi
    
    # Restore original files
    mv temp_backup/* . 2>/dev/null
    rmdir temp_backup
else
    echo "⚠️  test-vcn-only.tf not found, using main configuration"
    terraform init && terraform validate
fi

echo ""
echo "Next steps:"
echo "1. Run minimal test: terraform apply -target=oci_core_vcn.test_vcn"
echo "2. Clean up test: terraform destroy -target=oci_core_vcn.test_vcn"
echo "3. Deploy full infrastructure: terraform apply"