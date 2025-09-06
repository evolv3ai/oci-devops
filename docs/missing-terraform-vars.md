# Additional Terraform Variables Needed for OCI

Add these environment variables to your "oci-terra-vars" group:

## Required Variables:
- **TF_VAR_private_key_path**: `/home/semaphore/.oci/oci_api_key.pem`
- **TF_VAR_compartment_id**: `ocid1.compartment.oc1..aaaaaaa...` (your compartment OCID)
- **TF_VAR_ssh_public_key**: `ssh-rsa AAAAB3NzaC1yc2E...` (your SSH public key content)

## Optional but Recommended:
- **TF_VAR_instance_count**: `1`
- **TF_VAR_instance_name_prefix**: `semaphore-instance`
- **TF_VAR_environment**: `development`

## For Oracle Cloud Auth, you'll also need:
You need to upload your OCI private key file to the Semaphore container.

### Steps to add the private key:

1. **Create the OCI directory in Semaphore container:**
```bash
docker exec -it <semaphore-container-id> mkdir -p /home/semaphore/.oci
docker exec -it <semaphore-container-id> chown semaphore:semaphore /home/semaphore/.oci
docker exec -it <semaphore-container-id> chmod 700 /home/semaphore/.oci
```

2. **Copy your OCI private key to the container:**
```bash
docker cp ~/.oci/oci_api_key.pem <semaphore-container-id>:/home/semaphore/.oci/
docker exec -it <semaphore-container-id> chown semaphore:semaphore /home/semaphore/.oci/oci_api_key.pem
docker exec -it <semaphore-container-id> chmod 600 /home/semaphore/.oci/oci_api_key.pem
```

## Variable Values Explanation:

### TF_VAR_compartment_id
Your OCI compartment OCID where resources will be created.
Get from: OCI Console → Identity → Compartments

### TF_VAR_ssh_public_key  
The public key content (not file path) for SSH access.
Get from: `cat ~/.ssh/semaphore-oci-key.pub`

### TF_VAR_private_key_path
Path inside the Semaphore container: `/home/semaphore/.oci/oci_api_key.pem`

## After Adding Variables:
Your complete variable group should have:
- TF_VAR_tenancy_ocid ✅
- TF_VAR_user_ocid ✅  
- TF_VAR_fingerprint ✅
- TF_VAR_region ✅
- TF_VAR_private_key_path ← ADD
- TF_VAR_compartment_id ← ADD
- TF_VAR_ssh_public_key ← ADD
