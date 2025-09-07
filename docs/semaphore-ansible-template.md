# Semaphore Ansible Template Guide

## Overview
This guide provides instructions for creating and configuring Ansible templates in Semaphore UI for managing Oracle Cloud Infrastructure (OCI) resources deployed via Terraform.

## Template Configuration

### 1. Create a New Template

1. Navigate to your Semaphore project
2. Go to **Task Templates**
3. Click **New Template**
4. Configure as follows:

```yaml
Name: OCI Configuration Management
Description: Configure and manage OCI instances with Ansible
Type: ansible
Repository: Your Git repository with Ansible playbooks
Branch: main
Playbook: ansible/playbooks/configure-instance.yml
```

### 2. Inventory Setup

#### Dynamic Inventory from Terraform
Create an inventory template that uses Terraform outputs:

```ini
# ansible/inventory/terraform_hosts
[oci_instances]
{{ terraform_output.instance_public_ip }} ansible_user=opc ansible_ssh_private_key_file=/keys/oci_instance_key
```

#### Static Inventory Alternative
```ini
# ansible/inventory/static_hosts
[oci_instances]
instance1 ansible_host=132.145.xx.xx ansible_user=opc
instance2 ansible_host=132.145.xx.xx ansible_user=opc

[oci_instances:vars]
ansible_ssh_private_key_file=/keys/oci_instance_key
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### 3. Key Management

#### Using Semaphore Key Store
1. Go to **Key Store** in your project
2. Add new SSH key:
   - Name: `oci_instance_key`
   - Type: SSH
   - Private Key: Paste your private key content

3. Reference in template:
   - SSH Key: Select `oci_instance_key` from dropdown

## Working Playbook Examples

### 1. Basic System Configuration
```yaml
---
# ansible/playbooks/configure-instance.yml
- name: Configure OCI Instance
  hosts: oci_instances
  become: yes
  
  tasks:
    - name: Update system packages
      yum:
        name: '*'
        state: latest
      when: ansible_os_family == "RedHat"
    
    - name: Install essential packages
      yum:
        name:
          - git
          - docker
          - python3-pip
          - firewalld
        state: present
    
    - name: Start and enable Docker
      systemd:
        name: docker
        state: started
        enabled: yes
    
    - name: Configure firewall
      firewalld:
        service: "{{ item }}"
        permanent: yes
        state: enabled
      loop:
        - http
        - https
        - ssh
      notify: reload firewall
  
  handlers:
    - name: reload firewall
      systemd:
        name: firewalld
        state: reloaded
```

### 2. Application Deployment
```yaml
---
# ansible/playbooks/deploy-application.yml
- name: Deploy Application to OCI
  hosts: oci_instances
  become: yes
  
  vars:
    app_name: semaphore-worker
    app_port: 8080
    app_dir: /opt/applications
  
  tasks:
    - name: Create application directory
      file:
        path: "{{ app_dir }}/{{ app_name }}"
        state: directory
        owner: opc
        group: opc
        mode: '0755'
    
    - name: Copy application files
      copy:
        src: "../files/{{ app_name }}/"
        dest: "{{ app_dir }}/{{ app_name }}/"
        owner: opc
        group: opc
        mode: '0644'
    
    - name: Create systemd service
      template:
        src: templates/app.service.j2
        dest: "/etc/systemd/system/{{ app_name }}.service"
      notify: restart application
    
    - name: Start application service
      systemd:
        name: "{{ app_name }}"
        state: started
        enabled: yes
        daemon_reload: yes
  
  handlers:
    - name: restart application
      systemd:
        name: "{{ app_name }}"
        state: restarted
```

### 3. Security Hardening Playbook
```yaml
---
# ansible/playbooks/security-hardening.yml
- name: Security Hardening for OCI Instances
  hosts: oci_instances
  become: yes
  
  tasks:
    - name: Disable root SSH login
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^PermitRootLogin'
        line: 'PermitRootLogin no'
      notify: restart sshd
    
    - name: Configure SSH key-only authentication
      lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^PasswordAuthentication'
        line: 'PasswordAuthentication no'
      notify: restart sshd
    
    - name: Install and configure fail2ban
      block:
        - name: Install fail2ban
          yum:
            name: fail2ban
            state: present
        
        - name: Configure fail2ban
          template:
            src: templates/jail.local.j2
            dest: /etc/fail2ban/jail.local
        
        - name: Start fail2ban
          systemd:
            name: fail2ban
            state: started
            enabled: yes
    
    - name: Configure SELinux
      selinux:
        policy: targeted
        state: enforcing
    
    - name: Set up automatic security updates
      yum:
        name: yum-cron
        state: present
    
    - name: Configure yum-cron for security updates
      lineinfile:
        path: /etc/yum/yum-cron.conf
        regexp: '^update_cmd'
        line: 'update_cmd = security'
  
  handlers:
    - name: restart sshd
      systemd:
        name: sshd
        state: restarted
```

## Integration with Terraform State

### Reading Terraform Outputs
Create a playbook that reads Terraform state:

```yaml
---
# ansible/playbooks/get-terraform-outputs.yml
- name: Get Terraform Outputs
  hosts: localhost
  gather_facts: no
  
  tasks:
    - name: Read Terraform state
      terraform:
        project_path: "../terraform"
        state: present
      register: terraform_state
    
    - name: Extract instance IPs
      set_fact:
        instance_ips: "{{ terraform_state.outputs.instance_public_ips.value }}"
    
    - name: Generate dynamic inventory
      template:
        src: templates/dynamic_inventory.j2
        dest: ../inventory/dynamic_hosts
```

### Dynamic Inventory Template
```jinja2
# templates/dynamic_inventory.j2
[oci_instances]
{% for ip in instance_ips %}
instance{{ loop.index }} ansible_host={{ ip }} ansible_user=opc
{% endfor %}

[oci_instances:vars]
ansible_ssh_private_key_file=/keys/oci_instance_key
ansible_python_interpreter=/usr/bin/python3
```

## Variable Management

### Using Semaphore Variable Groups

1. Create a Variable Group: `oci_config`
2. Add variables:
   ```yaml
   OCI_REGION: us-ashburn-1
   OCI_COMPARTMENT: Production
   ANSIBLE_HOST_KEY_CHECKING: false
   ```

3. Reference in playbooks:
   ```yaml
   vars:
     region: "{{ lookup('env', 'OCI_REGION') }}"
     compartment: "{{ lookup('env', 'OCI_COMPARTMENT') }}"
   ```

### Vault for Sensitive Data
```bash
# Create encrypted variables
ansible-vault create ansible/group_vars/all/vault.yml

# In playbook
vars_files:
  - group_vars/all/vault.yml
```

## Context7 Integration

### Using Context7 for OCI Ansible Documentation

Use Context7 MCP tool to access comprehensive OCI Ansible collection documentation:

**Library ID**: `oracle/oci-ansible-collection`

**Example Queries**:
- "oci_compute_instance module parameters"
- "oci dynamic inventory plugin"
- "authentication setup for oci modules"
- "block volume attachment examples"
- "load balancer backend configuration"

**How to Use**:
1. Query Context7 for specific module documentation
2. Get up-to-date syntax and examples
3. Find best practices for OCI resource management
4. Troubleshoot module-specific issues

### Sample Context7 Workflow

```markdown
# When using a new OCI module:
1. Query: "oci_network_load_balancer module"
2. Review required parameters
3. Check authentication requirements
4. Understand return values for registered variables
```

## Advanced Patterns

### 1. Rolling Updates
```yaml
- name: Rolling update of instances
  hosts: oci_instances
  serial: 1  # Update one at a time
  max_fail_percentage: 0
  
  tasks:
    - name: Remove from load balancer
      oci_network_load_balancer_backend:
        load_balancer_id: "{{ lb_id }}"
        backend_name: "{{ inventory_hostname }}"
        state: absent
    
    - name: Perform update
      include_tasks: update_tasks.yml
    
    - name: Add back to load balancer
      oci_network_load_balancer_backend:
        load_balancer_id: "{{ lb_id }}"
        backend_name: "{{ inventory_hostname }}"
        state: present
```

### 2. Backup and Restore
```yaml
- name: Backup configuration
  hosts: oci_instances
  
  tasks:
    - name: Create backup directory
      file:
        path: /backup/{{ ansible_date_time.date }}
        state: directory
    
    - name: Backup application data
      archive:
        path: /opt/applications
        dest: /backup/{{ ansible_date_time.date }}/apps.tar.gz
    
    - name: Upload to Object Storage
      oci_object_storage_object:
        namespace: "{{ oci_namespace }}"
        bucket_name: backups
        object_name: "{{ inventory_hostname }}-{{ ansible_date_time.date }}.tar.gz"
        src: /backup/{{ ansible_date_time.date }}/apps.tar.gz
```

## Execution Best Practices

### 1. Pre-execution Checks
```yaml
- name: Pre-flight checks
  hosts: oci_instances
  gather_facts: yes
  
  tasks:
    - name: Check disk space
      assert:
        that:
          - ansible_mounts[0].size_available > 1073741824
        msg: "Insufficient disk space"
    
    - name: Verify connectivity
      wait_for:
        port: 22
        host: "{{ inventory_hostname }}"
        timeout: 30
```

### 2. Error Handling
```yaml
- name: Task with error handling
  block:
    - name: Risky operation
      command: /usr/local/bin/deploy.sh
      register: deploy_result
      
  rescue:
    - name: Rollback on failure
      command: /usr/local/bin/rollback.sh
    
    - name: Send notification
      mail:
        to: admin@example.com
        subject: "Deployment failed on {{ inventory_hostname }}"
        body: "{{ deploy_result.stderr }}"
  
  always:
    - name: Cleanup temporary files
      file:
        path: /tmp/deploy_temp
        state: absent
```

## Integration with Semaphore Features

### 1. Using Task Parameters
Configure template to accept runtime parameters:
- Enable: "Allow CLI arguments override"
- Use in playbook: `{{ ansible_extra_vars }}`

### 2. Scheduling
Create scheduled tasks for regular maintenance:
- Cron expression: `0 2 * * *` (2 AM daily)
- Task: Run security updates playbook

### 3. Notifications
Configure alerts in project settings:
- On failure: Send to Slack/email
- On success: Log to audit channel

## Additional Resources

- [OCI Ansible Collection Documentation](https://docs.oracle.com/en-us/iaas/tools/oci-ansible-collection/latest/index.html)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Semaphore Ansible Integration](https://docs.semaphoreui.com/integrations/ansible/)

---

*Last Updated: November 2024*
*Template Version: 1.0*
