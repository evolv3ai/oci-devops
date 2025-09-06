# Update OCI Inventory with your actual IP address
# Replace YOUR_OCI_IP with your actual Oracle Cloud instance public IP

$url = "http://localhost:3001"
$token = "fba4ojycp58ifun-ldnj93y-txsnnved5_eko_3l6kc="
$headers = @{"Authorization" = "Bearer $token"; "Content-Type" = "application/json"}
$projectId = 2
$inventoryId = 1
$sshKeyId = 4

# Replace this with your actual OCI instance IP
$YOUR_OCI_IP = "REPLACE_WITH_YOUR_ACTUAL_IP"

Write-Host "Updating inventory with IP: $YOUR_OCI_IP" -ForegroundColor Yellow

$inventoryContent = @"
[oci_servers]
$YOUR_OCI_IP ansible_user=opc

[oci_servers:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3
"@

$updateData = @{
    id = $inventoryId
    name = "oci-servers"
    project_id = $projectId
    inventory = $inventoryContent
    ssh_key_id = $sshKeyId
    type = "static"
}

$body = $updateData | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "$url/api/project/$projectId/inventory/$inventoryId" -Method PUT -Headers $headers -Body $body
    Write-Host "✓ Inventory updated successfully!" -ForegroundColor Green
    
    # Verify the update
    $updated = Invoke-RestMethod -Uri "$url/api/project/$projectId/inventory/$inventoryId" -Method GET -Headers $headers
    Write-Host "`nUpdated inventory content:" -ForegroundColor Cyan
    Write-Host $updated.inventory -ForegroundColor Gray
}
catch {
    Write-Host "✗ Error updating inventory: $($_.Exception.Message)" -ForegroundColor Red
}
