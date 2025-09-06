# Manual API Commands for Semaphore UI Setup
# Run these commands one by one in PowerShell

# Configuration
$url = "http://localhost:3001"
$token = "fba4ojycp58ifun-ldnj93y-txsnnved5_eko_3l6kc="
$headers = @{"Authorization" = "Bearer $token"; "Content-Type" = "application/json"}

# 1. Test API connection
Write-Host "1. Testing API connection..." -ForegroundColor Yellow
Invoke-RestMethod -Uri "$url/api/ping" -Method GET

# 2. List projects
Write-Host "`n2. Listing projects..." -ForegroundColor Yellow
$projects = Invoke-RestMethod -Uri "$url/api/projects" -Method GET -Headers $headers
$projects | Format-Table id, name, created

# 3. Get project ID (assuming first project)
$projectId = $projects[0].id
Write-Host "Using Project ID: $projectId" -ForegroundColor Green

# 4. List SSH keys
Write-Host "`n4. Listing SSH keys for project $projectId..." -ForegroundColor Yellow
$keys = Invoke-RestMethod -Uri "$url/api/project/$projectId/keys" -Method GET -Headers $headers
$keys | Format-Table id, name, type

# 5. Get SSH key ID (assuming first key)
$sshKeyId = $keys[0].id
Write-Host "Using SSH Key ID: $sshKeyId" -ForegroundColor Green

Write-Host "`n=== Ready to create inventory ===" -ForegroundColor Green
Write-Host "Project ID: $projectId" -ForegroundColor Cyan
Write-Host "SSH Key ID: $sshKeyId" -ForegroundColor Cyan
Write-Host "`nNext: Provide your OCI instance IP to create inventory" -ForegroundColor Yellow
