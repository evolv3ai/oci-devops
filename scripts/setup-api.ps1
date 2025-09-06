# Semaphore UI API Setup Script
# Using PowerShell to interact with Semaphore API

# Configuration
$SEMAPHORE_URL = "http://localhost:3001"
$API_TOKEN = "fba4ojycp58ifun-ldnj93y-txsnnved5_eko_3l6kc="
$HEADERS = @{
    "Authorization" = "Bearer $API_TOKEN"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

Write-Host "=== Semaphore UI API Setup ===" -ForegroundColor Green

# 1. Check API connectivity
Write-Host "`n1. Testing API connectivity..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$SEMAPHORE_URL/api/ping" -Method GET
    Write-Host "✓ API is accessible: $response" -ForegroundColor Green
} catch {
    Write-Host "✗ API connection failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 2. List projects
Write-Host "`n2. Listing projects..." -ForegroundColor Yellow
try {
    $projects = Invoke-RestMethod -Uri "$SEMAPHORE_URL/api/projects" -Method GET -Headers $HEADERS
    Write-Host "✓ Found $($projects.Count) project(s)" -ForegroundColor Green
    $projects | ForEach-Object { 
        Write-Host "  - Project ID: $($_.id), Name: $($_.name)" -ForegroundColor Cyan 
    }
    
    if ($projects.Count -eq 0) {
        Write-Host "No projects found. Creating one..." -ForegroundColor Yellow
        
        $newProject = @{
            name = "oracle-cloud-infrastructure"
            alert = $false
            alert_chat = ""
            max_parallel_tasks = 0
            type = ""
        } | ConvertTo-Json
        
        $project = Invoke-RestMethod -Uri "$SEMAPHORE_URL/api/projects" -Method POST -Headers $HEADERS -Body $newProject
        Write-Host "✓ Created project: $($project.name) (ID: $($project.id))" -ForegroundColor Green
        $PROJECT_ID = $project.id
    } else {
        $PROJECT_ID = $projects[0].id
        Write-Host "Using project ID: $PROJECT_ID" -ForegroundColor Cyan
    }
} catch {
    Write-Host "✗ Failed to list/create projects: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. List SSH keys for the project
Write-Host "`n3. Listing SSH keys..." -ForegroundColor Yellow
try {
    $keys = Invoke-RestMethod -Uri "$SEMAPHORE_URL/api/project/$PROJECT_ID/keys?sort=name`&order=asc" -Method GET -Headers $HEADERS
    Write-Host "✓ Found $($keys.Count) SSH key(s)" -ForegroundColor Green
    $keys | ForEach-Object { 
        Write-Host "  - Key ID: $($_.id), Name: $($_.name), Type: $($_.type)" -ForegroundColor Cyan 
    }
    
    if ($keys.Count -eq 0) {
        Write-Host "✗ No SSH keys found. Please add one through the UI first." -ForegroundColor Red
        exit 1
    }
    
    # Use the first SSH key found
    $SSH_KEY_ID = $keys[0].id
    Write-Host "Using SSH key ID: $SSH_KEY_ID" -ForegroundColor Cyan
} catch {
    Write-Host "✗ Failed to list SSH keys: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 4. Create inventory
Write-Host "`n4. Creating inventory..." -ForegroundColor Yellow

# Prompt for OCI instance IP
$OCI_IP = Read-Host "Enter your Oracle Cloud instance public IP address"
if ([string]::IsNullOrWhiteSpace($OCI_IP)) {
    Write-Host "✗ No IP address provided. Exiting." -ForegroundColor Red
    exit 1
}

$inventoryContent = @"
[oci_servers]
$OCI_IP ansible_user=opc

[oci_servers:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3
"@

$newInventory = @{
    name = "oci-servers"
    project_id = $PROJECT_ID
    inventory = $inventoryContent
    ssh_key_id = $SSH_KEY_ID
    become_key_id = $null
    repository_id = $null
    type = "static"
} | ConvertTo-Json

try {
    $inventory = Invoke-RestMethod -Uri "$SEMAPHORE_URL/api/project/$PROJECT_ID/inventory" -Method POST -Headers $HEADERS -Body $newInventory
    Write-Host "✓ Created inventory: $($inventory.name) (ID: $($inventory.id))" -ForegroundColor Green
    Write-Host "  - Type: $($inventory.type)" -ForegroundColor Cyan
    Write-Host "  - SSH Key ID: $($inventory.ssh_key_id)" -ForegroundColor Cyan
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "⚠ Inventory already exists. Listing existing inventories..." -ForegroundColor Yellow
        try {
            $inventories = Invoke-RestMethod -Uri "$SEMAPHORE_URL/api/project/$PROJECT_ID/inventory?sort=name`&order=asc" -Method GET -Headers $HEADERS
            $inventories | ForEach-Object { 
                Write-Host "  - Inventory ID: $($_.id), Name: $($_.name), Type: $($_.type)" -ForegroundColor Cyan 
            }
        } catch {
            Write-Host "✗ Failed to list existing inventories: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "✗ Failed to create inventory: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 5. List current inventories
Write-Host "`n5. Listing all inventories..." -ForegroundColor Yellow
try {
    $inventories = Invoke-RestMethod -Uri "$SEMAPHORE_URL/api/project/$PROJECT_ID/inventory?sort=name`&order=asc" -Method GET -Headers $HEADERS
    Write-Host "✓ Found $($inventories.Count) inventory(ies)" -ForegroundColor Green
    $inventories | ForEach-Object { 
        Write-Host "  - ID: $($_.id), Name: $($_.name), Type: $($_.type)" -ForegroundColor Cyan
        Write-Host "    SSH Key: $($_.ssh_key_id)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Failed to list inventories: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Create a repository for your Ansible playbooks" -ForegroundColor White
Write-Host "2. Create task templates" -ForegroundColor White
Write-Host "3. Run your automation tasks" -ForegroundColor White
