# Semaphore UI - Infrastructure Automation

## Overview
This repository contains Terraform and Ansible templates for automating Oracle Cloud Infrastructure (OCI) deployments through Semaphore UI.

## Quick Start

### Prerequisites
- Semaphore UI installed and running
- OCI account with configured CLI (`~/.oci/config`)
- Git repository connected to Semaphore
- Docker with volume mount for OCI config

### Setup

1. **Configure Docker Volume**
   Add to your `docker-compose.yml`:
   ```yaml
   services:
     semaphore:
       volumes:
         - ~/.oci:/oci:ro  # Mount OCI config as read-only
   ```

2. **Create Terraform Template**
   - Type: `terraform`
   - Directory: `terraform/`
   - Environment Variable: `TF_VAR_oci_cli_config = /oci/config`

3. **Create Ansible Template**
   - Type: `ansible`  
   - Playbook: `ansible/playbooks/configure-instance.yml`
   - Inventory: Select from Key Store

4. **Run Templates**
   - Execute Terraform first to provision infrastructure
   - Run Ansible to configure deployed resources

## Project Structure

```
semaphore-ui/
├── terraform/           # Infrastructure as Code
│   ├── main.tf         # Resource definitions
│   ├── variables.tf    # Variable declarations
│   ├── outputs.tf      # Output values
│   └── terraform.tfvars.example
├── ansible/            # Configuration Management
│   ├── playbooks/      # Ansible playbooks
│   └── inventory/      # Host inventories
├── docs/               # Documentation
│   ├── semaphore-terraform-template.md
│   ├── semaphore-ansible-template.md
│   └── context7-integration.md
└── docker-compose.yml  # Semaphore configuration
```

## Documentation

- [Terraform Template Guide](docs/semaphore-terraform-template.md) - Complete Terraform setup
- [Ansible Template Guide](docs/semaphore-ansible-template.md) - Ansible configuration
- [Context7 Integration](docs/context7-integration.md) - Documentation lookup tool

## Simple Working Configuration

### Terraform Authentication (Proven Method)
1. Mount OCI config: `~/.oci:/oci:ro` in Docker
2. Set environment variable: `TF_VAR_oci_cli_config = /oci/config`
3. Use Terraform template type (not shell/bash)

### Key Points
- ✅ Use Terraform template type directly
- ✅ Single environment variable needed
- ✅ OCI config mounted via Docker
- ❌ No wrapper scripts required
- ❌ No complex shell commands needed

## Common Tasks

### Deploy Infrastructure
```bash
# Via Semaphore UI
1. Navigate to Templates
2. Select "OCI Terraform Deploy"
3. Click "Run Task"
```

### Configure Instances
```bash
# Via Semaphore UI
1. Navigate to Templates
2. Select "OCI Configuration Management"
3. Click "Run Task"
```

### Troubleshooting

**Image Selection Error**
- Update filters in `data.oci_core_images`
- Verify shape compatibility
- Check operating system version

**Authentication Issues**
- Verify `~/.oci/config` exists
- Check Docker volume mount
- Ensure environment variable is set

## Security

- Never commit `terraform.tfvars` with real values
- Store sensitive data in Semaphore Variable Groups
- Use Semaphore Key Store for SSH keys
- Enable audit logging for compliance

## Contributing

1. Test changes in development environment
2. Update documentation for new features
3. Follow existing code patterns
4. Submit pull request with clear description

## Support

- [Semaphore UI Documentation](https://docs.semaphoreui.com/)
- [OCI Terraform Provider](https://registry.terraform.io/providers/oracle/oci/latest/docs)
- [OCI Ansible Collection](https://docs.oracle.com/en-us/iaas/tools/oci-ansible-collection/latest/)

## License

MIT License - See LICENSE file for details

---

*Version: 1.0.0*
*Last Updated: November 2024*
