# Oracle Cloud Infrastructure Inventory Setup for Semaphore UI

## Step-by-Step Inventory Configuration

### 1. Navigate to Inventory Section
- In Semaphore UI, go to your project
- Click on **"Inventory"** in the left sidebar
- Click **"New Inventory"** button

### 2. Basic Inventory Settings
- **Name:** `oci-servers` (or any descriptive name)
- **Type:** Select **"Static"**
- **SSH Key:** Select the SSH key you just created (`oci-ssh-key`)
- **Become Key:** Leave empty (unless you need sudo with different credentials)

### 3. Inventory Content (Static Format)
In the **Inventory** text area, add your OCI instance details:

```ini
# Basic OCI inventory structure
[oci_web_servers]
# Replace these IPs with your actual OCI instance IPs
10.0.1.100 ansible_user=opc ansible_host=10.0.1.100
10.0.1.101 ansible_user=opc ansible_host=10.0.1.101

[oci_db_servers]
10.0.1.200 ansible_user=opc ansible_host=10.0.1.200

[oci_all:children]
oci_web_servers
oci_db_servers

[oci_all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
ansible_python_interpreter=/usr/bin/python3
```

### 4. Important OCI-Specific Settings

#### Default User for Oracle Linux
- **Username:** `opc` (Oracle Linux default user)
- **Ubuntu:** Use `ubuntu` 
- **CentOS/RHEL:** Use `centos` or `ec2-user`

#### Network Configuration
Make sure your OCI Security Lists allow:
- **SSH (Port 22):** From your Semaphore server IP
- **ICMP:** For connectivity testing

### 5. Advanced Inventory Examples

#### With Public and Private IPs
```ini
[web_servers]
web1 ansible_host=129.213.xxx.xxx ansible_user=opc private_ip=10.0.1.100
web2 ansible_host=129.213.xxx.yyy ansible_user=opc private_ip=10.0.1.101

[web_servers:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
```

#### With Different Shapes/Roles
```ini
[micro_instances]
dev-server ansible_host=129.213.xxx.xxx ansible_user=opc shape=VM.Standard.E2.1.Micro

[standard_instances]
prod-web ansible_host=129.213.xxx.yyy ansible_user=ocp shape=VM.Standard2.1
prod-db ansible_host=129.213.xxx.zzz ansible_user=ocp shape=VM.Standard2.2

[production:children]
standard_instances

[development:children]
micro_instances
```

#### With Custom Variables
```ini
[app_servers]
app1 ansible_host=10.0.1.100 ansible_user=opc app_port=8080 environment=production
app2 ansible_host=10.0.1.101 ansible_user=opc app_port=8080 environment=staging

[app_servers:vars]
ansible_ssh_private_key_file=/home/semaphore/.ssh/id_rsa
ansible_become=yes
ansible_become_method=sudo
```

### 6. Getting Your OCI Instance IPs

#### From OCI Console
1. Login to Oracle Cloud Console
2. Navigate to **Compute > Instances**
3. Note the **Public IP** and **Private IP** for each instance

#### From OCI CLI (if configured)
```bash
oci compute instance list --compartment-id <compartment-ocid> --query 'data[*].{Name:"display-name", PublicIP:"public-ip", PrivateIP:"private-ip", State:"lifecycle-state"}'
```

### 7. Troubleshooting Inventory Issues

#### Test SSH Connection
Before using in Semaphore, test manually:
```bash
ssh -i ~/.ssh/semaphore-oci-key opc@YOUR_OCI_IP
```

#### Common Issues
- **Connection refused:** Check Security Lists allow SSH from your IP
- **Permission denied:** Verify public key is in OCI instance
- **Host key verification failed:** Add `-o StrictHostKeyChecking=no` to ansible_ssh_common_args

#### Debug in Semaphore
Enable debug mode in your playbooks:
```yaml
- hosts: all
  gather_facts: no
  tasks:
    - name: Test connection
      ping:
```

### 8. Next Steps After Inventory
1. **Test Inventory:** Create a simple ping task template
2. **Add Repository:** Point to your Ansible playbooks
3. **Create Task Template:** Combine inventory + repository + playbook
4. **Run Tasks:** Execute your automation

### 9. Dynamic Inventory (Advanced)
For large OCI deployments, consider dynamic inventory:
```python
#!/usr/bin/env python3
# OCI Dynamic Inventory Script
import json
import oci

# Configure OCI client
config = oci.config.from_file()
compute_client = oci.core.ComputeClient(config)

# Get instances
instances = compute_client.list_instances(compartment_id="your-compartment-id")

# Build inventory
inventory = {
    "_meta": {"hostvars": {}},
    "all": {"children": ["oci_instances"]},
    "oci_instances": {"hosts": []}
}

for instance in instances.data:
    if instance.lifecycle_state == "RUNNING":
        host_name = instance.display_name
        inventory["oci_instances"]["hosts"].append(host_name)
        inventory["_meta"]["hostvars"][host_name] = {
            "ansible_host": instance.public_ip,
            "ansible_user": "ocp",
            "private_ip": instance.private_ip,
            "shape": instance.shape
        }

print(json.dumps(inventory, indent=2))
```

Save this as `oci_inventory.py` in your repository and use **File** type inventory.
