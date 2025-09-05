# Semaphore UI + Oracle Cloud Infrastructure Automation

A complete Infrastructure as Code solution using Semaphore UI for orchestrating Terraform and Ansible to manage Oracle Cloud Infrastructure.

## 🚀 Features

- **Infrastructure Provisioning** with Terraform
- **Configuration Management** with Ansible  
- **Dynamic Variable Management** - Terraform outputs automatically feed into Ansible
- **Integrated Workflow** - Seamless Terraform → Ansible pipeline
- **Oracle Cloud Integration** - Optimized for OCI

## 📁 Project Structure

```
├── README.md                 # This file
├── docker-compose.yml        # Semaphore UI deployment
├── terraform/               # Terraform configurations
│   ├── main.tf              # Main infrastructure code
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   └── cloud-init.yml       # Instance initialization
├── ansible/                 # Ansible playbooks
│   └── configure-oci-basic.yml
├── scripts/                 # PowerShell automation scripts
│   ├── api-test.ps1         # Test Semaphore API
│   ├── setup-inventory.ps1  # Create inventory via API
│   ├── update-inventory.ps1 # Update inventory with IPs
│   └── fix-ssh.sh          # Fix SSH authentication
└── docs/                   # Documentation
    ├── ssh-key-generation-fix.md
    ├── oci-inventory-setup.md
    ├── semaphore-terraform-workflow.md
    └── missing-terraform-vars.md
```

## 🏗️ Architecture

```
Terraform (Build) → Provision OCI → Capture Outputs → Update Variables → Ansible (Deploy) → Configure Instances
```

## ⚡ Quick Start

### 1. Deploy Semaphore UI
```bash
docker compose up -d
```
Access: http://localhost:3001

### 2. Configure Authentication
- Create SSH keys for OCI instances
- Add OCI API credentials
- Set up Semaphore Key Store

### 3. Set Up Variable Groups
- **oci-terraform-vars**: Terraform configuration
- **oci-ansible-vars**: Ansible variables

### 4. Create Templates
- **Terraform Template**: Provision infrastructure
- **Ansible Template**: Configure instances

### 5. Run Workflow
1. Execute Terraform template → Creates OCI infrastructure
2. Terraform outputs update Semaphore variables
3. Execute Ansible template → Configures instances

## 📋 Prerequisites

- Docker and Docker Compose
- Oracle Cloud Infrastructure account
- OCI API keys and credentials
- SSH key pair for instance access

## 🔧 Configuration

### Required Environment Variables (Terraform)
```
TF_VAR_tenancy_ocid      # OCI Tenancy OCID
TF_VAR_user_ocid         # OCI User OCID  
TF_VAR_fingerprint       # API Key Fingerprint
TF_VAR_region            # OCI Region
TF_VAR_private_key_path  # Path to OCI private key
TF_VAR_compartment_id    # Compartment OCID
TF_VAR_ssh_public_key    # SSH public key content
```

### Ansible Variables (Captured from Terraform)
```json
{
  "OCI_INSTANCE_IP": "{{ terraform_outputs.primary_public_ip }}",
  "OCI_PRIVATE_IP": "{{ terraform_outputs.primary_private_ip }}",
  "OCI_INSTANCE_ID": "{{ terraform_outputs.primary_instance_id }}"
}
```

## 📖 Documentation

- **[SSH Key Setup](docs/ssh-key-generation-fix.md)** - Fix SSH authentication issues
- **[Inventory Configuration](docs/oci-inventory-setup.md)** - Set up dynamic inventory
- **[Terraform Workflow](docs/semaphore-terraform-workflow.md)** - Complete integration guide
- **[Missing Variables](docs/missing-terraform-vars.md)** - Required Terraform variables

## 🔨 Scripts

- **[api-test.ps1](scripts/api-test.ps1)** - Test Semaphore API connectivity
- **[setup-inventory.ps1](scripts/setup-inventory.ps1)** - Create inventory via API
- **[update-inventory.ps1](scripts/update-inventory.ps1)** - Update inventory with new IPs
- **[fix-ssh.sh](scripts/fix-ssh.sh)** - Fix container SSH directory structure

## 🎯 Benefits

✅ **Infrastructure as Code** - All infrastructure defined and version controlled  
✅ **Dynamic Variables** - Automatic IP capture and inventory updates  
✅ **Integrated Workflow** - Seamless Terraform to Ansible pipeline  
✅ **Oracle Cloud Optimized** - Purpose-built for OCI  
✅ **Repeatable Deployments** - Consistent environment provisioning  
✅ **Web UI Management** - Easy-to-use Semaphore interface  

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the workflow
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

- Check the [documentation](docs/) for detailed guides
- Review the [workflow guide](docs/semaphore-terraform-workflow.md) for complete setup
- Ensure all [required variables](docs/missing-terraform-vars.md) are configured

---

**Built with ❤️ for Infrastructure as Code automation**
# oci-devops
