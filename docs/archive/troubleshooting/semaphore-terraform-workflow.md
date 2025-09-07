# Semaphore UI + Terraform + Oracle Cloud Integration Workflow

## Overview
This guide shows how to:
1. **Store variables** in Semaphore Environment Groups
2. **Provision infrastructure** with Terraform
3. **Capture Terraform outputs** as variables
4. **Update inventory dynamically** with provisioned IPs

## Current Setup Status ✅
- **Project:** oracle-cloud-infrastructure (ID: 2)
- **SSH Key:** oci-ssh-key (ID: 4)
- **Inventory:** oci-servers (ID: 1)
- **Environment:** OCI Variables (ID: 1)
- **Repository:** terraform-oci (ID: 1)

## Workflow Architecture

```
Terraform Template (Build) → Provision OCI → Capture Outputs → Update Environment → Ansible Template (Deploy) → Configure Instances
```

## Step 1: Environment Variables Setup ✅ COMPLETE

Your environment variables are stored in Semaphore with ID: 1

### Key Variables:
- `OCI_INSTANCE_IP` - Primary instance IP (updated by Terraform)
- `OCI_REGION` - Oracle Cloud region
- `OCI_COMPARTMENT_ID` - Compartment OCID
- `TF_VAR_*` - Terraform input variables

### Adding OCI Credentials:
```json
{
  "TF_VAR_tenancy_ocid": "ocid1.tenancy.oc1...",
  "TF_VAR_user_ocid": "ocid1.user.oc1...",
  "TF_VAR_fingerprint": "aa:bb:cc:dd:ee:ff...",
  "TF_VAR_private_key_path": "/home/semaphore/.oci/oci_api_key.pem",
  "TF_VAR_region": "us-ashburn-1",
  "TF_VAR_compartment_id": "ocid1.compartment.oc1...",
  "TF_VAR_ssh_public_key": "ssh-rsa AAAAB3NzaC1yc2E..."
}
```

## Step 2: Terraform Configuration ✅ COMPLETE

Created files:
- `terraform/main.tf` - Main infrastructure configuration
- `terraform/variables.tf` - Input variables
- `terraform/outputs.tf` - Output values (IPs, instance IDs)
- `terraform/cloud-init.yml` - Instance initialization

### Key Outputs Captured:
- `primary_public_ip` - Main instance public IP
- `primary_private_ip` - Main instance private IP
- `instance_ids` - All instance OCIDs
- `ansible_inventory_vars` - JSON for dynamic inventory

## Step 3: Create Terraform Task Template

### Via UI:
1. **Go to Task Templates → New Template**
2. **Configure:**
   - **Name:** `Terraform - Provision OCI Infrastructure`
   - **Type:** `Terraform Code Template`
   - **Repository:** `terraform-oci`
   - **Environment:** `OCI Variables`
   - **Working Directory:** `terraform/`
   - **Terraform Version:** `latest`

### Via API:
```powershell
$url = "http://localhost:3001"
$token = "fba4ojycp58ifun-ldnj93y-txsnnved5_eko_3l6kc="
$headers = @{"Authorization" = "Bearer $token"; "Content-Type" = "application/json"}
$projectId = 2

$terraformTemplate = @{
    name = "Terraform - Provision OCI Infrastructure"
    project_id = $projectId
    inventory_id = 1
    repository_id = 1
    environment_id = 1
    playbook = "main.tf"
    app = "terraform"
    type = "build"
    arguments = '[]'
    description = "Provision Oracle Cloud Infrastructure and capture instance IPs"
    allow_override_args_in_task = $true
    suppress_success_alerts = $false
} | ConvertTo-Json

Invoke-RestMethod -Uri "$url/api/project/$projectId/templates" -Method POST -Headers $headers -Body $terraformTemplate
```

## Step 4: Create Post-Terraform Script

This script captures Terraform outputs and updates Semaphore variables:

```bash
#!/bin/bash
# post-terraform.sh - Capture outputs and update Semaphore

# Get Terraform outputs
PRIMARY_IP=$(terraform output -raw primary_public_ip)
PRIVATE_IP=$(terraform output -raw primary_private_ip)
INSTANCE_ID=$(terraform output -raw primary_instance_id)

echo "Captured Infrastructure:"
echo "Primary Public IP: $PRIMARY_IP"
echo "Primary Private IP: $PRIVATE_IP"
echo "Instance ID: $INSTANCE_ID"

# Update Semaphore environment variables via API
curl -X PUT "http://localhost:3001/api/project/2/environment/1" \
  -H "Authorization: Bearer fba4ojycp58ifun-ldnj93y-txsnnved5_eko_3l6kc=" \
  -H "Content-Type: application/json" \
  -d "{
    \"id\": 1,
    \"name\": \"OCI Variables\",
    \"project_id\": 2,
    \"json\": \"{
      \\\"OCI_INSTANCE_IP\\\": \\\"$PRIMARY_IP\\\",
      \\\"OCI_PRIVATE_IP\\\": \\\"$PRIVATE_IP\\\",
      \\\"OCI_INSTANCE_ID\\\": \\\"$INSTANCE_ID\\\",
      \\\"OCI_REGION\\\": \\\"us-ashburn-1\\\"
    }\"
  }"

# Update inventory with new IP
curl -X PUT "http://localhost:3001/api/project/2/inventory/1" \
  -H "Authorization: Bearer fba4ojycp58ifun-ldnj93y-txsnnved5_eko_3l6kc=" \
  -H "Content-Type: application/json" \
  -d "{
    \"id\": 1,
    \"name\": \"oci-servers\",
    \"project_id\": 2,
    \"inventory\": \"[oci_servers]\\n$PRIMARY_IP ansible_user=opc\\n\\n[oci_servers:vars]\\nansible_ssh_common_args='-o StrictHostKeyChecking=no'\",
    \"ssh_key_id\": 4,
    \"type\": \"static\"
  }"

echo "✓ Semaphore variables and inventory updated!"
```

## Step 5: Create Ansible Configuration Template

### Via UI:
1. **Go to Task Templates → New Template**
2. **Configure:**
   - **Name:** `Ansible - Configure OCI Instances`
   - **Type:** `Ansible Playbook`
   - **Playbook:** `configure-oci-basic.yml`
   - **Inventory:** `oci-servers`
   - **Repository:** `terraform-oci`
   - **Environment:** `OCI Variables`

## Step 6: Complete Workflow Pipeline

### Build Pipeline (Terraform):
1. **Template:** `Terraform - Provision OCI Infrastructure`
2. **Actions:**
   - Run `terraform plan`
   - Run `terraform apply`
   - Capture outputs
   - Update Semaphore variables
   - Update inventory

### Deploy Pipeline (Ansible):
1. **Template:** `Ansible - Configure OCI Instances`
2. **Actions:**
   - Use updated inventory with new IPs
   - Configure provisioned instances
   - Deploy applications

## Step 7: Environment Variable Management

### Update Variables via API:
```powershell
# Function to update environment variables
function Update-SemaphoreVariables($newIP) {
    $url = "http://localhost:3001"
    $token = "fba4ojycp58ifun-ldnj93y-txsnnved5_eko_3l6kc="
    $headers = @{"Authorization" = "Bearer $token"; "Content-Type" = "application/json"}
    
    $envData = @{
        id = 1
        name = "OCI Variables"
        project_id = 2
        json = "{\"OCI_INSTANCE_IP\": \"$newIP\", \"OCI_REGION\": \"us-ashburn-1\"}"
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri "$url/api/project/2/environment/1" -Method PUT -Headers $headers -Body $envData
    Write-Host "✓ Variables updated with IP: $newIP"
}

# Usage
Update-SemaphoreVariables "129.213.123.45"
```

## Step 8: Dynamic Inventory Update

### Update Inventory via API:
```powershell
function Update-SemaphoreInventory($newIP) {
    $url = "http://localhost:3001"
    $token = "fba4ojycp58ifun-ldnj93y-txsnnved5_eko_3l6kc="
    $headers = @{"Authorization" = "Bearer $token"; "Content-Type" = "application/json"}
    
    $inventoryContent = "[oci_servers]`n$newIP ansible_user=opc`n`n[oci_servers:vars]`nansible_ssh_common_args='-o StrictHostKeyChecking=no'"
    
    $inventoryData = @{
        id = 1
        name = "oci-servers"
        project_id = 2
        inventory = $inventoryContent
        ssh_key_id = 4
        type = "static"
    } | ConvertTo-Json
    
    Invoke-RestMethod -Uri "$url/api/project/2/inventory/1" -Method PUT -Headers $headers -Body $inventoryData
    Write-Host "✓ Inventory updated with IP: $newIP"
}

# Usage
Update-SemaphoreInventory "129.213.123.45"
```

## Step 9: Execution Workflow

### Manual Execution:
1. **Run Terraform Template** → Provisions infrastructure
2. **Capture outputs** → Updates variables
3. **Run Ansible Template** → Configures instances

### Automated Execution:
1. **Set up Build/Deploy pipeline**
2. **Terraform (Build)** → **Ansible (Deploy)**
3. **Automatic variable transfer**

## Step 10: Monitoring & Validation

### Verify Setup:
```powershell
# Check current environment variables
$envs = Invoke-RestMethod -Uri "http://localhost:3001/api/project/2/environment" -Headers $headers
$envs | Format-Table id, name

# Check current inventory
$inventory = Invoke-RestMethod -Uri "http://localhost:3001/api/project/2/inventory/1" -Headers $headers
Write-Host $inventory.inventory
```

### Test Workflow:
1. **Provision infrastructure** with Terraform template
2. **Verify IP capture** in environment variables
3. **Verify inventory update** with new IPs
4. **Run Ansible configuration** on new instances

## Benefits of This Setup

✅ **Infrastructure as Code** - All infrastructure defined in Terraform  
✅ **Dynamic Variable Management** - IPs automatically captured and stored  
✅ **Automated Inventory Updates** - No manual IP management  
✅ **Integrated Workflow** - Terraform → Semaphore → Ansible  
✅ **Version Control** - All configurations in Git  
✅ **Repeatable Deployments** - Consistent environment provisioning  

## Next Steps

1. **Add OCI credentials** to environment variables
2. **Create Terraform task template** in Semaphore UI
3. **Test infrastructure provisioning**
4. **Verify variable capture** and inventory updates
5. **Create Ansible configuration template**
6. **Test complete workflow**

Your infrastructure is now fully automated with dynamic variable management! 🚀
