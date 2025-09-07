# Semaphore Infrastructure RooCode Custom Mode

## Overview
This is a custom RooCode mode for managing Semaphore UI infrastructure templates, specifically designed for working with Terraform and Ansible automation in Oracle Cloud Infrastructure (OCI).

## Installation

1. **In RooCode/VSCode:**
   - Open Command Palette (`Ctrl+Shift+P`)
   - Select "RooCode: Add Custom Mode"
   - Copy the contents of `semaphore-infra-mode.yml`
   - Paste into the custom mode configuration

2. **Activate the Mode:**
   - Use the mode selector in RooCode
   - Choose "🔧 Semaphore Infrastructure"

## Mode Capabilities

### Terraform Template Management
- Creates and debugs Terraform templates
- Fixes common OCI provider issues
- Manages infrastructure as code
- Handles image selection problems

### Ansible Template Development
- Develops configuration playbooks
- Sets up dynamic inventory
- Implements security hardening
- Manages application deployments

### Context7 Integration
- Real-time documentation lookup
- Syntax verification
- Best practices guidance
- Error resolution

### Semaphore API Operations
- Template CRUD operations
- Task execution
- Environment management
- Key store integration

## Key Features

### 1. Environment Awareness
The mode knows about:
- Docker container at `http://localhost:3001`
- GitHub repo: `https://github.com/evolv3ai/oci-devops`
- OCI config mount: `~/.oci:/oci:ro`
- API token for automation

### 2. Documentation Access
Automatic reference to:
- `docs/semaphore-terraform-template.md`
- `docs/semaphore-ansible-template.md`
- `docs/context7-integration.md`
- `docs/semaphoreui-swagger.yml`

### 3. Working Configuration
Pre-configured with proven setup:
- Terraform template type (not shell)
- Single env variable: `TF_VAR_oci_cli_config`
- Fixed image selection filters
- Proper Docker volume mounts

## Usage Examples

### Creating a Terraform Template
```yaml
Agent: "I'll create a new Terraform template for OCI infrastructure"
1. Checks existing templates via API
2. Uses Context7 for resource syntax
3. Creates template with proper configuration
4. Tests with simple VCN first
```

### Debugging Template Issues
```yaml
Agent: "Let me troubleshoot the image selection error"
1. Checks task output in Semaphore
2. Verifies environment variables
3. Uses Context7 for error resolution
4. Applies fix from documentation
```

### Ansible Integration
```yaml
Agent: "Setting up Ansible playbook for configuration"
1. Uses Terraform outputs for inventory
2. Stores SSH keys in Key Store
3. Tests connectivity
4. Deploys configuration playbook
```

## Context7 Libraries

### Terraform OCI Provider
- **Library ID**: `oracle/terraform-provider-oci`
- **Common Queries**:
  - "oci_core_instance resource"
  - "oci_core_vcn examples"
  - "image data source filters"
  - "authentication configuration"

### Ansible OCI Collection
- **Library ID**: `oracle/oci-ansible-collection`
- **Common Queries**:
  - "oci_compute_instance module"
  - "dynamic inventory plugin"
  - "authentication setup"
  - "module parameters"

## API Integration

### PowerShell Examples
```powershell
# List all templates
$headers = @{
    "Authorization" = "Bearer fba4ojycp58ifun-ldnj93y-txsnnved5_eko_3l6kc="
    "Content-Type" = "application/json"
}

$templates = Invoke-RestMethod `
    -Uri "http://localhost:3001/api/project/1/templates" `
    -Headers $headers `
    -Method GET
```

### Available Scripts
- `scripts/setup-api.ps1` - Initial API setup
- `scripts/create-inventory.ps1` - Create Ansible inventory
- `scripts/update-inventory.ps1` - Update inventory
- `scripts/api-test.ps1` - Test API connectivity

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "Invalid index" error | Fix image data source filters in main.tf |
| "404-NotAuthorizedOrNotFound" | Verify compartment OCID and permissions |
| "Template execution failed" | Check Semaphore logs and env variables |
| "Authentication failed" | Verify Docker volume mount for OCI config |

## Best Practices

1. **Security**
   - Never commit real OCIDs or keys
   - Use Semaphore Variable Groups
   - Abstract sensitive data

2. **Development**
   - Test incrementally
   - Use Context7 for verification
   - Document template changes

3. **Troubleshooting**
   - Check Semaphore logs first
   - Verify environment variables
   - Use Context7 for documentation

## Repository Structure
```
semaphore-ui/
├── terraform/           # Infrastructure code
├── ansible/            # Configuration playbooks
├── scripts/            # API automation
├── docs/               # Documentation
└── semaphore-infra-mode.yml  # This custom mode
```

## Support Resources

- **Semaphore API**: See `docs/semaphoreui-swagger.yml`
- **Terraform Guide**: See `docs/semaphore-terraform-template.md`
- **Ansible Guide**: See `docs/semaphore-ansible-template.md`
- **Context7 Guide**: See `docs/context7-integration.md`

---

*Custom Mode Version: 1.0*
*Created: November 2024*
*Repository: https://github.com/evolv3ai/oci-devops*
