# Documentation

## Template Guides

### Infrastructure Provisioning
- **[Terraform Template Guide](semaphore-terraform-template.md)** - Complete guide for creating Terraform templates in Semaphore UI
  - OCI provider configuration
  - Resource examples
  - Troubleshooting image selection
  - Context7 integration

### Configuration Management  
- **[Ansible Template Guide](semaphore-ansible-template.md)** - Guide for Ansible playbook templates
  - Dynamic inventory from Terraform
  - Security hardening playbooks
  - Application deployment patterns
  - Integration with Terraform outputs

### Setup & Configuration
- **[OCI Terraform Setup](oci-terraform-setup.md)** - Simplified setup guide
  - Working configuration (proven in production)
  - Docker volume mounting
  - Single environment variable solution
  - Common troubleshooting

### Tools & Integration
- **[Context7 Integration](context7-integration.md)** - Documentation lookup tool
  - How to use Context7 for template development
  - Query patterns and best practices
  - Library IDs for OCI resources
  - Troubleshooting with Context7

## API Reference
- **[Semaphore API Swagger](semaphoreui-swagger.yml)** - OpenAPI specification for Semaphore UI API
  - Endpoint documentation
  - Request/response schemas
  - Authentication methods

## Archive Folder
The `archive/` directory contains:
- Historical implementation documents
- Experimental scripts (not for production)
- Troubleshooting logs from development
- Test scripts and iterations

**Note**: Archive folder should be moved to Dropbox after repository cleanup is complete.

## Quick Links

- [Main README](../README.md) - Project overview and quick start
- [Terraform Directory](../terraform/) - Infrastructure as Code files
- [Ansible Directory](../ansible/) - Configuration management playbooks
- [Scripts Directory](../scripts/) - PowerShell scripts for Semaphore API

---

*Documentation Version: 1.0*
*Last Updated: November 2024*
