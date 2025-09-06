# Semaphore UI Terraform Integration Troubleshooting

## 1. Primary Request and Intent
User was setting up Terraform automation in Semaphore UI for Oracle Cloud Infrastructure (OCI) deployments. Initial error showed Terraform execution failing with "not a directory" error. User needed to:
- Fix Terraform template configuration in Semaphore
- Pass OCI credentials securely without committing to Git
- Mount local ~/.oci folder for secrets management
- Get Terraform plan/apply working with proper variable configuration

## 2. Key Technical Concepts
- Semaphore UI (self-hosted CI/CD)
- Terraform for OCI infrastructure provisioning
- Docker volume mounting for secrets
- Environment variable handling (TF_VAR_ prefix)
- OCI authentication (API keys, tenancy/user/compartment OCIDs)
- terraform.tfvars file configuration
- Docker Compose configuration

## 3. Files and Code Sections

**semaphoreui-swagger.yml**
- OpenAPI spec defining Semaphore's API
- Referenced for understanding API endpoints and data models

**terraform/cloud-init.yml**
- Initially misconfigured as Terraform playbook
- Actually a cloud-init configuration file for instance provisioning

**docker-compose.yml**
- Fixed volume naming inconsistencies (semaphore_config vs semaphore-config)
- Added mount for ~/.oci folder:
```yaml
volumes:
  - ~/.oci:/oci:ro  # Mount your .oci folder as read-only
  - semaphore-data:/var/lib/semaphore
  - semaphore-config:/etc/semaphore
  - semaphore-tmp:/tmp/semaphore
```

## 4. Errors and Fixes

**Error 1: "fork/exec /usr/local/bin/terraform: not a directory"**
- Fix: Changed template playbook from "terraform/cloud-init.yml" to "terraform/"
- User feedback: Chose option 1 to keep Terraform app type

**Error 2: "No value for required variable" (multiple Terraform variables)**
- Attempted fixes:
  - Set environment variables with TF_VAR_ prefix (kept getting wiped)
  - Tried JSON field in environment configuration
  - Created terraform.tfvars file
- User feedback: Can't push tfvars to GitHub due to sensitive data

**Error 3: SSH key format issue**
- User had PEM format instead of SSH format
- Fix: Advised to generate proper SSH key with `ssh-keygen -t rsa`

**Error 4: Docker volume naming inconsistency**
- `semaphore_config` vs `semaphore-config` mismatch
- Fix: Standardized all volumes to use hyphens

**Error 5: "did not find a proper configuration for private key"**
- Fix: Located mounted key at `/oci/oci_api_key.pem`
- Set `TF_VAR_private_key_path = /oci/oci_api_key.pem`

## 5. Problem Solving
- Diagnosed template misconfiguration (cloud-init vs Terraform)
- Identified Semaphore's environment variable persistence bug
- Implemented Docker volume mounting for secure credential handling
- Resolved path issues for OCI private key access
- Fixed container naming issues (semaphore vs semaphore-ui)

## 6. All User Messages
1. "I set up the task template for Terraform inside Semaphore, and it is called 'instance initiation'. It points to 'terraform cloud - init.yml' and this is the error I received."
2. "try using your mcp tool now. (Also, the api is a solid way to poll resources)"
3. "I chose option 1. Ran the task and here's the raw_output"
4. [Showed environment variable configuration screenshots]
5. "I've added these two"
6. "I added: terraform\terraform.tfvars got this output:"
7. [Showed updated environment variables screenshot]
8. "two Qs: 1. what's the diff between Variables and Secrets? 2. can we use oci auth tokens?"
9. "should these be with or without the TF_VAR_ prefix?"
10. "I added: terraform\terraform.tfvars got this output:"
11. "It has to pull the terraform.tfvars from a local drive OUTSIDE of the container. I can't push the vars file to github."
12. "We can't seem to make TF_VAR_ work. It drops the vars everytime we run a task."
13. "i want to use the ~/.oci folder for the local mount"
14. [Showed docker-compose.yml with volume errors]
15. "ok...so we've made progress. Using the terraform secrets and the TF_VAR_ prefix is working."
16. "the .oci key EITHER needs to be pulled from the local ~/.oci/ folder outside of the container, OR needs to be pulled from either the Key Store or Variable Groups within Semaphore."
17. [Showed PowerShell errors with docker exec commands]
18. [Showed container file listing with OCI key present]
19. "1. Summarize this thread using N:\Dropbox\06_AI\claude\claude-cmd-compact.md 2. Save it to the project folder as an .md file"

## 7. Pending Tasks
- Run Terraform task to verify the fix works with correct private key path

## 8. Current Work
Just resolved the final private key path issue by locating the mounted OCI key at `/oci/oci_api_key.pem` and updating the environment variable. The user confirmed the key is accessible in the container. The last action was setting `TF_VAR_private_key_path = /oci/oci_api_key.pem` in the Semaphore environment.

## 9. Final Solution Summary

### Working Configuration:
1. **Docker Compose**: Mount ~/.oci folder as read-only volume at `/oci`
2. **Semaphore Template**: 
   - App: `terraform`
   - Playbook: `terraform/`
   - Arguments: `[]` (or `["-var-file=/oci/terraform.tfvars"]` if using tfvars)
3. **Environment Variables** (with TF_VAR_ prefix):
   - `TF_VAR_tenancy_ocid`
   - `TF_VAR_user_ocid`
   - `TF_VAR_fingerprint`
   - `TF_VAR_region`
   - `TF_VAR_compartment_id`
   - `TF_VAR_ssh_public_key`
   - `TF_VAR_private_key_path = /oci/oci_api_key.pem`

### Key Lessons:
- Semaphore has issues with environment variable persistence that were resolved after container restart
- Docker volume mounts are the most reliable way to handle sensitive credentials
- The TF_VAR_ prefix is required for environment variables but not in .tfvars files
- Container name matters for docker exec commands (semaphore-ui not semaphore)
- PowerShell requires different syntax for redirecting stderr (`2>$null` instead of `2>/dev/null`)
