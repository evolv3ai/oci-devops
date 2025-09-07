# How to Populate Semaphore Variables for OCI

## Prerequisites
You need these values from your OCI account. Here's how to get them:

### 1. Get Your Tenancy OCID
- Log into OCI Console
- Click Profile icon → Tenancy
- Copy the OCID (starts with `ocid1.tenancy.oc1..`)

### 2. Get Your User OCID
- Click Profile icon → User Settings
- Copy the OCID (starts with `ocid1.user.oc1..`)

### 3. Get Your API Key Fingerprint
- In User Settings → API Keys
- Find your key and copy the fingerprint
- Format: `AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99`

### 4. Get Your Compartment OCID
- Navigate to Identity → Compartments
- Find your compartment (or create one)
- Copy the OCID (starts with `ocid1.compartment.oc1..`)

### 5. Generate SSH Key (if needed)
```bash
ssh-keygen -t rsa -b 2048 -f ~/.ssh/oci_instance_key
cat ~/.ssh/oci_instance_key.pub
```

## Setting Variables in Semaphore

### Navigate to Variable Groups
1. Open Semaphore UI
2. Go to your project
3. Click Settings → Variable Groups
4. Edit `oci-terra-vars` group

### Required Variables to Set

Copy and paste these into Semaphore, replacing the example values with your actual values:

```bash
# OCI Authentication (REQUIRED - Get from OCI Console)
TF_VAR_tenancy_ocid = ocid1.tenancy.oc1..aaaaaaaXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
TF_VAR_user_ocid = ocid1.user.oc1..aaaaaaaYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
TF_VAR_fingerprint = AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99
TF_VAR_private_key_path = /oci/oci_api_key.pem

# Resource Configuration (REQUIRED)
TF_VAR_compartment_id = ocid1.compartment.oc1..aaaaaaaZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ
TF_VAR_ssh_public_key = ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC...your-full-public-key-here...

# Region Configuration (REQUIRED)
TF_VAR_region = us-ashburn-1

# Config File Path (REQUIRED - This was your key discovery!)
TF_VAR_oci_cli_config = /oci/config

# Optional - Only if using auth tokens
TF_VAR_auth_token = 
```

### Example with Real-Looking Values

```bash
TF_VAR_tenancy_ocid = ocid1.tenancy.oc1..aaaaaaaab4w7ytpqd3xjnhcdimzpxj7wxkwrfqxdczm3ehr2jwo2xhmqzta
TF_VAR_user_ocid = ocid1.user.oc1..aaaaaaaajxsckmfapq45uwqmjhcd7ytiw6s7bdmokq2ns5hqxwhqz3a4qzq
TF_VAR_fingerprint = 3d:8f:ca:16:bb:42:9e:71:2b:c4:d8:5f:e2:3a:91:4c
TF_VAR_private_key_path = /oci/oci_api_key.pem
TF_VAR_compartment_id = ocid1.compartment.oc1..aaaaaaaa5qnwiox2xm3qzw7tpfxwichqzg3wvfgbrhe2jwo2xhmqhcd7ytq
TF_VAR_ssh_public_key = ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfR8wjY4ZV8Oi1tPvPkZ3LhSxNmFPm5Gvfx+5mYnGMfHhJ5pjVgKw1x2NqPvmhoWNcs3Kdf8QxbR6dWj3cDZe6hNtbB9tuWd4F5dDCEJpX+4qUbaLiqIb9QSphvTbH0vNXqLJb+9YM8JbXvpZQH1dxvzXBqDQq8k/MqQdLmqVY3xNmFPm5 user@hostname
TF_VAR_region = us-ashburn-1
TF_VAR_oci_cli_config = /oci/config
```

## Verification Steps

### 1. Check Variables are Set
In Semaphore UI, you should see all variables listed with values (not empty)

### 2. Verify Docker Mount
Check your `docker-compose.yml` has:
```yaml
volumes:
  - ~/.oci:/oci:ro
```

### 3. Test with Simple Terraform
Run your Terraform template in Semaphore. If authentication works, you'll see:
```
Initializing provider plugins...
- Using previously-installed oracle/oci v5.47.0

Terraform has been successfully initialized!
```

### 4. If It Fails
Common issues:
- **Empty variables**: Make sure all TF_VAR_* have actual values
- **Wrong fingerprint**: Verify it matches your API key in OCI Console
- **Missing private key**: Ensure ~/.oci/oci_api_key.pem exists locally
- **Docker mount issue**: Restart Semaphore container after updating docker-compose.yml

## Security Notes

- ✅ These values are stored securely in Semaphore
- ✅ Never commit these values to Git
- ✅ Use terraform.tfvars.example for documentation only
- ✅ Rotate API keys periodically

## Quick Checklist

- [ ] Tenancy OCID obtained from OCI Console
- [ ] User OCID obtained from OCI Console
- [ ] API Key created and fingerprint copied
- [ ] Private key file exists at ~/.oci/oci_api_key.pem
- [ ] Compartment OCID obtained or created
- [ ] SSH key pair generated
- [ ] All TF_VAR_* variables populated in Semaphore
- [ ] Docker volume mounted in docker-compose.yml
- [ ] Test run successful

---

Once all variables are populated, your Terraform will authenticate successfully using the variable-based method you discovered!