# OCI Infrastructure Management

This directory contains the centralized Oracle Cloud Infrastructure (OCI) configuration and scripts that are shared between KASM and Coolify deployments.

## 📁 Directory Purpose

Since both KASM Workspaces and Coolify use the same OCI infrastructure with only resource allocation differences, this directory provides:

- **Unified Configuration**: Single `.env` file for all OCI settings
- **Shared Scripts**: Common infrastructure provisioning scripts
- **Resource Management**: Centralized resource allocation and limits
- **DRY Principle**: Avoid duplication between kasm/ and coolify/ folders

## 🏗️ Architecture Overview

```
oci/
├── .env.example           # Master configuration template
├── .env                   # Your actual configuration (git-ignored)
├── infrastructure-setup.sh    # Unified provisioning script
├── preflight-check.sh     # OCI CLI installation and setup
├── cleanup.sh             # Resource cleanup script
├── validate-env.sh        # Configuration validation
└── README.md             # This file
```

## 🚀 Quick Start

1. **Copy the configuration template**:
   ```bash
   cp oci/.env.example oci/.env
   ```

2. **Edit the configuration**:
   ```bash
   # Set your deployment type
   DEPLOYMENT_TYPE=both  # or "kasm", "coolify", "none"
   
   # Default resource allocations are already set:
   # KASM: 2 OCPUs, 12GB RAM, 80GB Storage
   # Coolify: 2 OCPUs, 12GB RAM, 100GB Storage
   ```

3. **Run the setup**:
   ```bash
   cd oci
   ./preflight-check.sh      # Install OCI CLI
   ./validate-env.sh          # Verify configuration
   ./infrastructure-setup.sh  # Provision infrastructure
   ```

## 📊 Resource Allocation

### Oracle Cloud Free Tier Limits
- **Total OCPUs**: 4 (ARM Ampere A1)
- **Total Memory**: 24 GB
- **Total Storage**: 200 GB

### Default Configurations

#### KASM Workspaces
```bash
KASM_INSTANCE_OCPUS=2      # Default
KASM_INSTANCE_MEMORY_GB=12  # Default
KASM_INSTANCE_STORAGE_GB=80 # Default (80GB for KASM)
```

#### Coolify
```bash
COOLIFY_INSTANCE_OCPUS=2      # Default
COOLIFY_INSTANCE_MEMORY_GB=12  # Default
COOLIFY_INSTANCE_STORAGE_GB=100 # Default (100GB for Coolify)
```

### Deployment Options

#### Option 1: KASM Only
```bash
DEPLOYMENT_TYPE=kasm
# Uses default: 2 OCPUs, 12GB RAM, 80GB Storage
# Can scale up to 4 OCPUs, 24GB RAM if needed
```

#### Option 2: Coolify Only
```bash
DEPLOYMENT_TYPE=coolify
# Uses default: 2 OCPUs, 12GB RAM, 100GB Storage
```

#### Option 3: Both (Within Free Tier)
```bash
DEPLOYMENT_TYPE=both
# Total: 4 OCPUs, 24GB RAM, 180GB Storage
# Each server gets its default allocation
```

## 🔧 Configuration Variables

### Essential Variables
| Variable | Description | Example |
|----------|-------------|---------|
| `DEPLOYMENT_TYPE` | What to deploy | `kasm`, `coolify`, `both`, `none` |
| `TENANCY_OCID` | OCI Tenancy ID | `ocid1.tenancy.oc1..xxx` |
| `REGION` | OCI Region | `us-ashburn-1` |
| `COMPARTMENT_NAME` | Resource compartment | `DevOpsLab` |

### Resource Variables (with Defaults)
| Variable | Description | Default |
|----------|-------------|---------|
| `KASM_INSTANCE_OCPUS` | KASM CPU cores | 2 |
| `KASM_INSTANCE_MEMORY_GB` | KASM Memory | 12 |
| `KASM_INSTANCE_STORAGE_GB` | KASM Storage | 80 |
| `COOLIFY_INSTANCE_OCPUS` | Coolify CPU cores | 2 |
| `COOLIFY_INSTANCE_MEMORY_GB` | Coolify Memory | 12 |
| `COOLIFY_INSTANCE_STORAGE_GB` | Coolify Storage | 100 |

## 🔄 Integration with Application Folders

The OCI infrastructure is used by:

### KASM Folder (`../kasm/`)
- Uses OCI infrastructure for KASM Workspaces
- Default: 2 OCPUs, 12GB RAM, 80GB Storage
- Deploys on port 8443
- Container-based workspace solution

### Coolify Folder (`../coolify/`)
- Uses OCI infrastructure for Coolify PaaS
- Default: 2 OCPUs, 12GB RAM, 100GB Storage
- Deploys on port 8000
- Self-hosted platform-as-a-service

## 📝 Scripts Description

### `infrastructure-setup.sh`
Main provisioning script that:
- Creates compartment, VCN, and subnet
- Provisions instances based on `DEPLOYMENT_TYPE`
- Allocates resources per server defaults
- Configures security lists per server type
- Outputs instance IPs to `.env`

### `preflight-check.sh`
Ensures OCI CLI is installed and configured:
- Detects OS (Windows/Linux/macOS)
- Installs OCI CLI if missing
- Configures API keys
- Validates connectivity

### `validate-env.sh`
Validates configuration before deployment:
- Checks required variables
- Validates resource limits (ensures total doesn't exceed free tier)
- Verifies account credentials
- Tests OCI API access

### `cleanup.sh`
Removes all OCI resources:
- Terminates instances
- Deletes network resources
- Removes compartment (optional)
- Useful for testing and cost management

## 🔐 Security Considerations

1. **Never commit `.env` files** - They contain sensitive credentials
2. **Use separate SSH keys** for OCI infrastructure
3. **Rotate API keys regularly**
4. **Enable audit logging** in OCI console
5. **Use compartments** for resource isolation

## 🆘 Troubleshooting

### Common Issues

1. **"Insufficient host capacity"**
   - Try a different availability domain
   - Use default resource allocations (already optimized)
   - Wait and retry (free tier resources are limited)

2. **"API key not found"**
   - Run `./preflight-check.sh` to set up OCI CLI
   - Verify key path in `.env`

3. **"Compartment not found"**
   - Script will create it automatically
   - Ensure you have proper IAM permissions

4. **"Resource limit exceeded"**
   - Check you're within free tier limits (4 OCPUs, 24GB RAM total)
   - Default configurations are designed to fit within limits

## 📚 Related Documentation

- [OCI Free Tier](https://www.oracle.com/cloud/free/)
- [OCI CLI Documentation](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm)
- [KASM Setup Guide](../kasm/README.md)
- [Coolify Setup Guide](../coolify/README.md)

## 💡 Best Practices

1. **Use defaults**: The default allocations are optimized for each service
2. **Monitor usage**: Check OCI console for resource consumption
3. **Automate backups**: Set up regular snapshots
4. **Use tags**: Label resources for easy management
5. **Document changes**: Keep track of configuration modifications

## 🚦 Status Indicators

The scripts use color-coded output:
- 🟢 **Green**: Success
- 🟡 **Yellow**: Warning (non-critical)
- 🔴 **Red**: Error (critical)
- 🔵 **Blue**: Information
- ⚪ **Gray**: Debug (verbose mode)

## 📞 Support

For issues or questions:
1. Check the [troubleshooting section](#-troubleshooting)
2. Review [workflow diagrams](../docs/workflows/)
3. Consult OCI documentation
4. Open an issue in the repository

## 🎯 Why Separate OCI Folder?

The OCI folder exists because:
1. **Resource Management**: Both KASM and Coolify use OCI, only differing in resource allocation
2. **Code Reuse**: Avoid duplicating infrastructure scripts
3. **Centralized Config**: Single source of truth for OCI settings
4. **Easier Maintenance**: Update infrastructure code in one place
5. **Clear Separation**: Infrastructure vs Application concerns

## 📈 Scaling Guidelines

### When to Scale Up KASM
- More than 10 concurrent users
- Heavy workloads (development, graphics)
- Production environment
- Scale to: 4 OCPUs, 24GB RAM

### When to Scale Up Coolify
- Hosting multiple applications
- High traffic websites
- Database-heavy workloads
- Scale to: 4 OCPUs, 16GB RAM

### Resource Distribution Examples
```bash
# Development Setup (Both services, minimal)
KASM: 2 OCPUs, 8GB RAM, 50GB Storage
Coolify: 2 OCPUs, 8GB RAM, 50GB Storage

# Production KASM Focus
KASM: 3 OCPUs, 18GB RAM, 100GB Storage
Coolify: 1 OCPU, 6GB RAM, 50GB Storage

# Production Coolify Focus
KASM: 1 OCPU, 6GB RAM, 50GB Storage
Coolify: 3 OCPUs, 18GB RAM, 100GB Storage
```

Remember: The defaults (2/12/80 for KASM, 2/12/100 for Coolify) are recommended starting points that work well for most use cases.