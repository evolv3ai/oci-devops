# Semaphore UI API Setup Script
$SEMAPHORE_URL = "http://localhost:3001"
$API_TOKEN = "fba4ojycp58ifun-ldnj93y-txsnnved5_eko_3l6kc="
$HEADERS = @{
    "Authorization" = "Bearer $API_TOKEN"
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

Write-Host "=== Semaphore UI API Setup ===" -ForegroundColor Green

# 1. Test API
Write-Host "`n1. Testing API..." -ForegroundColor Yellow
$pingResponse = Invoke-RestMethod -Uri "$SEMAPHORE_URL/api/ping" -Method GET
Write-Host "✓ API Response: $pingResponse" -ForegroundColor Green

# 2. List projects
Write-Host "`n2. Listing projects..." -ForegroundColor Yellow
$projects = Invoke-RestMethod -Uri "$SEMAPHORE_URL/api/projects" -Method GET -Headers $HEADERS
Write-Host "✓ Found $($projects.Count) project(s)" -ForegroundColor Green

if ($projects.Count -gt 0) {
    $PROJECT_ID = $projects[0].id
    Write-Host "Using project: $($projects[0].name) (ID: $PROJECT_ID)" -ForegroundColor Cyan
    
    # 3. List SSH keys
    Write-Host "`n3. Listing SSH keys..." -ForegroundColor Yellow
    $keysUrl = "$SEMAPHORE_URL/api/project/$PROJECT_ID/keys"
    $keys = Invoke-RestMethod -Uri $keysUrl -Method GET -Headers $HEADERS
    Write-Host "✓ Found $($keys.Count) SSH key(s)" -ForegroundColor Green
    
    if ($keys.Count -gt 0) {
        $SSH_KEY_ID = $keys[0].id
        Write-Host "Using SSH key: $($keys[0].name) (ID: $SSH_KEY_ID)" -ForegroundColor Cyan
        
        # 4. Get OCI IP from user
        Write-Host "`n4. Setting up inventory..." -ForegroundColor Yellow
        $OCI_IP = Read-Host "Enter your Oracle Cloud instance public IP"
        
        if ($OCI_IP) {
            # 5. Create inventory
            $inventoryContent = "[oci_servers]`n$OCI_IP ansible_user=opc`n`n[oci_servers:vars]`nansible_ssh_common_args='-o StrictHostKeyChecking=no'"
            
            $newInventory = @{
                name = "oci-servers"
                project_id = $PROJECT_ID
                inventory = $inventoryContent
                ssh_key_id = $SSH_KEY_ID
                type = "static"
            } | ConvertTo-Json
            
            try {
                $inventoryUrl = "$SEMAPHORE_URL/api/project/$PROJECT_ID/inventory"
                $inventory = Invoke-RestMethod -Uri $inventoryUrl -Method POST -Headers $HEADERS -Body $newInventory
                Write-Host "✓ Created inventory: $($inventory.name) (ID: $($inventory.id))" -ForegroundColor Green
            }
            catch {
                Write-Host "⚠ Inventory might already exist or error occurred: $($_.Exception.Message)" -ForegroundColor Yellow
            }
            
            # 6. List all inventories
            Write-Host "`n6. Current inventories:" -ForegroundColor Yellow
            $inventories = Invoke-RestMethod -Uri $inventoryUrl -Method GET -Headers $HEADERS
            $inventories | ForEach-Object { 
                Write-Host "  - $($_.name) (ID: $($_.id), Type: $($_.type))" -ForegroundColor Cyan 
            }
        }
    } else {
        Write-Host "✗ No SSH keys found. Add one through the UI first." -ForegroundColor Red
    }
} else {
    Write-Host "✗ No projects found. Create one through the UI first." -ForegroundColor Red
}

Write-Host "`n=== Done ===" -ForegroundColor Green
