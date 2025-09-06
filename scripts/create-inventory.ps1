# Create inventory with the SSH key
$url = "http://localhost:3001"
$token = "fba4ojycp58ifun-ldnj93y-txsnnved5_eko_3l6kc="
$headers = @{"Authorization" = "Bearer $token"; "Content-Type" = "application/json"}
$projectId = 2

# First, let's list all keys to see what we have
Write-Host "Current SSH keys:" -ForegroundColor Yellow
$keys = Invoke-RestMethod -Uri "$url/api/project/$projectId/keys" -Method GET -Headers $headers
$keys | Format-Table id, name, type

# Find SSH key (not "none" type)
$sshKey = $keys | Where-Object { $_.type -eq "ssh" }

if ($sshKey) {
    $sshKeyId = $sshKey.id
    Write-Host "Found SSH key: $($sshKey.name) (ID: $sshKeyId)" -ForegroundColor Green
} else {
    Write-Host "No SSH key found. Using first available key..." -ForegroundColor Yellow
    $sshKeyId = $keys[0].id
}

# Get OCI IP from user
$ociIP = Read-Host "`nEnter your Oracle Cloud instance public IP address"

if ($ociIP) {
    # Create inventory
    $inventoryData = @{
        name = "oci-servers"
        project_id = $projectId
        inventory = "[oci_servers]`n$ociIP ansible_user=opc`n`n[oci_servers:vars]`nansible_ssh_common_args='-o StrictHostKeyChecking=no'"
        ssh_key_id = $sshKeyId
        type = "static"
    }
    
    $body = $inventoryData | ConvertTo-Json
    Write-Host "`nCreating inventory..." -ForegroundColor Yellow
    Write-Host "Inventory content:" -ForegroundColor Gray
    Write-Host $inventoryData.inventory -ForegroundColor Gray
    
    try {
        $result = Invoke-RestMethod -Uri "$url/api/project/$projectId/inventory" -Method POST -Headers $headers -Body $body
        Write-Host "`n✓ Inventory created successfully!" -ForegroundColor Green
        Write-Host "Inventory ID: $($result.id)" -ForegroundColor Cyan
        Write-Host "Name: $($result.name)" -ForegroundColor Cyan
        Write-Host "Type: $($result.type)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "`n✗ Error creating inventory:" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        
        # Try to list existing inventories
        Write-Host "`nExisting inventories:" -ForegroundColor Yellow
        try {
            $inventories = Invoke-RestMethod -Uri "$url/api/project/$projectId/inventory" -Method GET -Headers $headers
            $inventories | Format-Table id, name, type
        } catch {
            Write-Host "Could not list inventories: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "No IP address provided. Exiting." -ForegroundColor Red
}
