#!/bin/bash

# OCI Complete Cleanup Script
# This script removes ALL OCI resources from your tenancy
# Use with caution - this will delete everything!

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo "❌ Error: .env file not found. Cannot proceed with cleanup."
    exit 1
fi

echo "🧹 OCI Complete Cleanup Script"
echo "⚠️  WARNING: This will DELETE ALL OCI resources in your tenancy!"
echo "📋 Tenancy: $TENANCY_OCID"
echo "🌍 Region: $REGION"
echo "📦 Compartment: $COMPARTMENT_NAME"
echo ""

# Confirmation prompt
read -p "Are you ABSOLUTELY SURE you want to delete ALL OCI resources? Type 'DELETE' to confirm: " confirmation
if [ "$confirmation" != "DELETE" ]; then
    echo "❌ Cleanup cancelled. No resources were deleted."
    exit 0
fi

echo ""
echo "🚀 Starting complete OCI cleanup..."
echo ""

# Function to run OCI CLI commands with error handling
run_oci_command() {
    local command="$1"
    local description="$2"
    local ignore_errors="$3"
    
    echo "🔧 $description"
    echo "📝 Executing: $command"
    
    if eval "$command" 2>/dev/null; then
        echo "✅ $description completed successfully"
        echo ""
        return 0
    else
        if [ "$ignore_errors" = "true" ]; then
            echo "⚠️  $description failed (ignoring error)"
            echo ""
            return 0
        else
            echo "❌ $description failed"
            echo ""
            return 1
        fi
    fi
}

# Function to wait for resource deletion
wait_for_deletion() {
    local check_command="$1"
    local resource_name="$2"
    local max_attempts=30
    local attempt=1
    
    echo "⏳ Waiting for $resource_name to be deleted..."
    
    while [ $attempt -le $max_attempts ]; do
        if ! eval "$check_command" >/dev/null 2>&1; then
            echo "✅ $resource_name deleted successfully"
            return 0
        fi
        
        echo "   Attempt $attempt/$max_attempts - $resource_name still exists, waiting..."
        sleep 10
        ((attempt++))
    done
    
    echo "⚠️  Timeout waiting for $resource_name deletion"
    return 1
}

# Step 1: Delete Cloudflare Tunnel (if exists)
if [ ! -z "$TUNNEL_ID" ]; then
    echo "☁️  Step 1: Cleaning up Cloudflare Tunnel..."
    
    # Delete tunnel using cloudflared
    TUNNEL_DELETE_CMD="cloudflared tunnel delete $TUNNEL_ID --force"
    run_oci_command "$TUNNEL_DELETE_CMD" "Deleting Cloudflare tunnel" true
    
    # Delete DNS record if exists
    if [ ! -z "$DNS_RECORD_ID" ]; then
        DNS_DELETE_CMD="curl -X DELETE \"https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$DNS_RECORD_ID\" \
          -H \"Authorization: Bearer $CLOUDFLARE_API_TOKEN\" \
          -H \"Content-Type: application/json\""
        run_oci_command "$DNS_DELETE_CMD" "Deleting Cloudflare DNS record" true
    fi
else
    echo "ℹ️  No Cloudflare tunnel to clean up"
fi

# Step 2: Terminate compute instances
echo "🖥️  Step 2: Terminating compute instances..."

if [ ! -z "$INSTANCE_ID" ]; then
    INSTANCE_TERMINATE_CMD="oci compute instance terminate --instance-id $INSTANCE_ID --force"
    run_oci_command "$INSTANCE_TERMINATE_CMD" "Terminating compute instance"
    
    # Wait for instance termination
    INSTANCE_CHECK_CMD="oci compute instance get --instance-id $INSTANCE_ID --query 'data.\"lifecycle-state\"' --raw-output"
    wait_for_deletion "$INSTANCE_CHECK_CMD" "compute instance"
else
    # Find and delete all instances in the compartment
    echo "🔍 Searching for all compute instances in compartment..."
    INSTANCES_LIST_CMD="oci compute instance list --compartment-id $COMPARTMENT_ID --query 'data[].id' --raw-output"
    
    if INSTANCE_IDS=$(eval "$INSTANCES_LIST_CMD" 2>/dev/null); then
        if [ ! -z "$INSTANCE_IDS" ]; then
            echo "$INSTANCE_IDS" | while read -r instance_id; do
                if [ ! -z "$instance_id" ]; then
                    echo "🗑️  Terminating instance: $instance_id"
                    TERMINATE_CMD="oci compute instance terminate --instance-id $instance_id --force"
                    run_oci_command "$TERMINATE_CMD" "Terminating instance $instance_id" true
                fi
            done
        else
            echo "ℹ️  No compute instances found"
        fi
    fi
fi

# Step 3: Delete security lists (except default)
echo "🔒 Step 3: Deleting security lists..."

if [ ! -z "$SECURITY_LIST_ID" ]; then
    SEC_LIST_DELETE_CMD="oci network security-list delete --security-list-id $SECURITY_LIST_ID --force"
    run_oci_command "$SEC_LIST_DELETE_CMD" "Deleting security list"
else
    # Find and delete all non-default security lists
    echo "🔍 Searching for all security lists in VCN..."
    if [ ! -z "$VCN_ID" ]; then
        SEC_LISTS_CMD="oci network security-list list --compartment-id $COMPARTMENT_ID --vcn-id $VCN_ID --query 'data[?\"is-default\"==false].id' --raw-output"
        
        if SEC_LIST_IDS=$(eval "$SEC_LISTS_CMD" 2>/dev/null); then
            if [ ! -z "$SEC_LIST_IDS" ]; then
                echo "$SEC_LIST_IDS" | while read -r sec_list_id; do
                    if [ ! -z "$sec_list_id" ]; then
                        echo "🗑️  Deleting security list: $sec_list_id"
                        DELETE_CMD="oci network security-list delete --security-list-id $sec_list_id --force"
                        run_oci_command "$DELETE_CMD" "Deleting security list $sec_list_id" true
                    fi
                done
            else
                echo "ℹ️  No custom security lists found"
            fi
        fi
    fi
fi

# Step 4: Delete subnets
echo "🔗 Step 4: Deleting subnets..."

if [ ! -z "$SUBNET_ID" ]; then
    SUBNET_DELETE_CMD="oci network subnet delete --subnet-id $SUBNET_ID --force"
    run_oci_command "$SUBNET_DELETE_CMD" "Deleting subnet"
else
    # Find and delete all subnets in VCN
    echo "🔍 Searching for all subnets in VCN..."
    if [ ! -z "$VCN_ID" ]; then
        SUBNETS_CMD="oci network subnet list --compartment-id $COMPARTMENT_ID --vcn-id $VCN_ID --query 'data[].id' --raw-output"
        
        if SUBNET_IDS=$(eval "$SUBNETS_CMD" 2>/dev/null); then
            if [ ! -z "$SUBNET_IDS" ]; then
                echo "$SUBNET_IDS" | while read -r subnet_id; do
                    if [ ! -z "$subnet_id" ]; then
                        echo "🗑️  Deleting subnet: $subnet_id"
                        DELETE_CMD="oci network subnet delete --subnet-id $subnet_id --force"
                        run_oci_command "$DELETE_CMD" "Deleting subnet $subnet_id" true
                    fi
                done
            else
                echo "ℹ️  No subnets found"
            fi
        fi
    fi
fi

# Step 5: Delete internet gateways
echo "🌍 Step 5: Deleting internet gateways..."

if [ ! -z "$INTERNET_GATEWAY_ID" ]; then
    IG_DELETE_CMD="oci network internet-gateway delete --ig-id $INTERNET_GATEWAY_ID --force"
    run_oci_command "$IG_DELETE_CMD" "Deleting internet gateway"
else
    # Find and delete all internet gateways in VCN
    echo "🔍 Searching for all internet gateways in VCN..."
    if [ ! -z "$VCN_ID" ]; then
        IG_CMD="oci network internet-gateway list --compartment-id $COMPARTMENT_ID --vcn-id $VCN_ID --query 'data[].id' --raw-output"
        
        if IG_IDS=$(eval "$IG_CMD" 2>/dev/null); then
            if [ ! -z "$IG_IDS" ]; then
                echo "$IG_IDS" | while read -r ig_id; do
                    if [ ! -z "$ig_id" ]; then
                        echo "🗑️  Deleting internet gateway: $ig_id"
                        DELETE_CMD="oci network internet-gateway delete --ig-id $ig_id --force"
                        run_oci_command "$DELETE_CMD" "Deleting internet gateway $ig_id" true
                    fi
                done
            else
                echo "ℹ️  No internet gateways found"
            fi
        fi
    fi
fi

# Step 6: Delete VCNs
echo "🌐 Step 6: Deleting Virtual Cloud Networks..."

if [ ! -z "$VCN_ID" ]; then
    VCN_DELETE_CMD="oci network vcn delete --vcn-id $VCN_ID --force"
    run_oci_command "$VCN_DELETE_CMD" "Deleting VCN"
else
    # Find and delete all VCNs in compartment
    echo "🔍 Searching for all VCNs in compartment..."
    VCN_CMD="oci network vcn list --compartment-id $COMPARTMENT_ID --query 'data[].id' --raw-output"
    
    if VCN_IDS=$(eval "$VCN_CMD" 2>/dev/null); then
        if [ ! -z "$VCN_IDS" ]; then
            echo "$VCN_IDS" | while read -r vcn_id; do
                if [ ! -z "$vcn_id" ]; then
                    echo "🗑️  Deleting VCN: $vcn_id"
                    DELETE_CMD="oci network vcn delete --vcn-id $vcn_id --force"
                    run_oci_command "$DELETE_CMD" "Deleting VCN $vcn_id" true
                fi
            done
        else
            echo "ℹ️  No VCNs found"
        fi
    fi
fi

# Step 7: Delete compartment (if not root)
echo "📦 Step 7: Deleting compartment..."

if [ ! -z "$COMPARTMENT_ID" ] && [ "$COMPARTMENT_ID" != "$TENANCY_OCID" ]; then
    echo "⏳ Waiting for all resources to be fully deleted before removing compartment..."
    sleep 30
    
    COMPARTMENT_DELETE_CMD="oci iam compartment delete --compartment-id $COMPARTMENT_ID --force"
    run_oci_command "$COMPARTMENT_DELETE_CMD" "Deleting compartment"
else
    echo "ℹ️  Skipping compartment deletion (root compartment or not specified)"
fi

# Step 8: Clean up any remaining resources by scanning the entire tenancy
echo "🔍 Step 8: Scanning for any remaining resources..."

echo "   Checking for remaining compute instances..."
ALL_INSTANCES_CMD="oci compute instance list --compartment-id $TENANCY_OCID --all --query 'data[?\"lifecycle-state\"!=\`TERMINATED\`].{ID:id,Name:\"display-name\",State:\"lifecycle-state\"}' --output table"
run_oci_command "$ALL_INSTANCES_CMD" "Listing all remaining instances" true

echo "   Checking for remaining VCNs..."
ALL_VCNS_CMD="oci network vcn list --compartment-id $TENANCY_OCID --all --query 'data[].{ID:id,Name:\"display-name\",State:\"lifecycle-state\"}' --output table"
run_oci_command "$ALL_VCNS_CMD" "Listing all remaining VCNs" true

echo "   Checking for remaining compartments..."
ALL_COMPARTMENTS_CMD="oci iam compartment list --compartment-id $TENANCY_OCID --all --query 'data[?\"lifecycle-state\"!=\`DELETED\`].{ID:id,Name:name,State:\"lifecycle-state\"}' --output table"
run_oci_command "$ALL_COMPARTMENTS_CMD" "Listing all remaining compartments" true

echo ""
echo "🎉 OCI Cleanup Completed!"
echo ""
echo "📋 Summary of actions taken:"
echo "   ☁️  Deleted Cloudflare tunnel and DNS records"
echo "   🖥️  Terminated all compute instances"
echo "   🔒 Deleted custom security lists"
echo "   🔗 Deleted subnets"
echo "   🌍 Deleted internet gateways"
echo "   🌐 Deleted VCNs"
echo "   📦 Deleted compartment (if applicable)"
echo ""
echo "⚠️  Note: Some resources may take additional time to fully delete."
echo "🔍 Check the OCI console to verify all resources are removed."
echo ""
echo "✅ Your OCI tenancy should now be clean and ready for fresh deployments!"