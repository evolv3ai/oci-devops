# Context7 Integration Guide for Semaphore Templates

## Overview
Context7 is an MCP (Model Context Protocol) tool that provides access to comprehensive documentation for various libraries and frameworks. This guide explains how to leverage Context7 when developing Terraform and Ansible templates for Semaphore UI.

## What is Context7?

Context7 is a documentation retrieval system that allows you to:
- Access up-to-date library documentation
- Get specific examples and best practices
- Find detailed parameter descriptions
- Troubleshoot error messages with context-aware help

## Using Context7 in Template Development

### Step 1: Identify the Library

First, identify the correct library ID for your use case:

| Technology | Library ID | Use Case |
|------------|------------|----------|
| OCI Terraform | `oracle/terraform-provider-oci` | Infrastructure provisioning |
| OCI Ansible | `oracle/oci-ansible-collection` | Configuration management |
| AWS Terraform | `hashicorp/terraform-provider-aws` | AWS infrastructure |
| Kubernetes | `kubernetes/kubernetes` | Container orchestration |

### Step 2: Query for Documentation

Use Context7 with specific queries to get relevant documentation:

```markdown
# For Terraform OCI Provider
Query: "oci_core_instance resource"
Library: oracle/terraform-provider-oci
Topic: compute instances

# For Ansible OCI Collection  
Query: "oci_compute_instance module"
Library: oracle/oci-ansible-collection
Topic: instance management
```

### Step 3: Apply Documentation to Templates

Use the retrieved documentation to:
1. Verify correct syntax
2. Understand required vs optional parameters
3. Find working examples
4. Identify dependencies

## Terraform Template Development with Context7

### Common Terraform Queries

#### 1. Resource Documentation
```markdown
Query: "oci_core_vcn resource attributes"
Purpose: Understand VCN configuration options
Expected Response: Required arguments, optional arguments, attributes exported
```

#### 2. Data Source Filters
```markdown
Query: "oci_core_images data source filter examples"
Purpose: Fix image selection issues
Expected Response: Filter syntax, available filter fields, example configurations
```

#### 3. Authentication Methods
```markdown
Query: "provider authentication config_file_profile"
Purpose: Understand authentication options
Expected Response: Config file setup, environment variables, instance principal
```

### Terraform Workflow Example

1. **Planning a new resource**:
   ```markdown
   Context7 Query: "oci_load_balancer_load_balancer resource"
   Extract: Required parameters, dependencies, example configuration
   ```

2. **Debugging an error**:
   ```markdown
   Error: "Invalid value for shape_config"
   Context7 Query: "shape_config block structure compute instance"
   Solution: Find correct nested block syntax
   ```

3. **Finding best practices**:
   ```markdown
   Context7 Query: "terraform oci tagging strategy"
   Apply: Implement consistent tagging across resources
   ```

## Ansible Template Development with Context7

### Common Ansible Queries

#### 1. Module Parameters
```markdown
Query: "oci_compute_instance module parameters"
Purpose: Understand module options
Expected Response: Required params, optional params, return values
```

#### 2. Dynamic Inventory
```markdown
Query: "oci dynamic inventory plugin configuration"
Purpose: Set up dynamic host discovery
Expected Response: Plugin setup, filters, grouping options
```

#### 3. Authentication Setup
```markdown
Query: "oci ansible authentication setup"
Purpose: Configure OCI authentication for Ansible
Expected Response: Config file usage, environment variables, instance principal
```

### Ansible Workflow Example

1. **Using a new module**:
   ```markdown
   Context7 Query: "oci_network_load_balancer_backend module"
   Extract: Required parameters, state management, return values
   ```

2. **Complex operations**:
   ```markdown
   Context7 Query: "oci block volume attachment examples"
   Apply: Implement volume management playbook
   ```

3. **Error troubleshooting**:
   ```markdown
   Error: "Module requires oci python SDK"
   Context7 Query: "oci ansible collection requirements"
   Solution: Install required Python packages
   ```

## Best Practices for Context7 Usage

### 1. Specific Queries Yield Better Results

❌ **Too Broad**: "oci terraform"
✅ **Specific**: "oci_core_instance shape_config memory_in_gbs"

❌ **Vague**: "ansible errors"  
✅ **Targeted**: "oci_compute_instance module requires parameters"

### 2. Include Context in Queries

When troubleshooting, include:
- Error message keywords
- Resource or module name
- Specific parameter or attribute

Example:
```markdown
Query: "oci_core_images filter operating_system_version available values"
Context: Fixing "empty images list" error
```

### 3. Cross-Reference Documentation

Always verify:
- Parameter names haven't changed
- Deprecated features aren't being used
- New required parameters haven't been added

### 4. Version-Specific Queries

When possible, specify versions:
```markdown
Query: "terraform provider oci version 5.x breaking changes"
Purpose: Understand migration requirements
```

## Practical Examples

### Example 1: Creating a Load Balancer

**Step 1: Research**
```markdown
Context7 Query: "oci_load_balancer_load_balancer complete example"
Library: oracle/terraform-provider-oci
```

**Step 2: Extract Requirements**
- Required: compartment_id, display_name, shape, subnet_ids
- Optional: is_private, ip_mode, network_security_group_ids

**Step 3: Implement**
```hcl
resource "oci_load_balancer_load_balancer" "main" {
  compartment_id = var.compartment_id
  display_name   = "semaphore-lb"
  shape          = "flexible"
  
  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 100
  }
  
  subnet_ids = [oci_core_subnet.public.id]
}
```

### Example 2: Ansible Security Hardening

**Step 1: Find Modules**
```markdown
Context7 Query: "oci ansible security group rule management"
Library: oracle/oci-ansible-collection
```

**Step 2: Understand Parameters**
- Module: oci_network_security_group_security_rule
- Required: network_security_group_id, direction, protocol

**Step 3: Create Playbook**
```yaml
- name: Configure security rules
  oci_network_security_group_security_rule:
    network_security_group_id: "{{ nsg_id }}"
    direction: INGRESS
    protocol: "6"  # TCP
    source: "0.0.0.0/0"
    tcp_options:
      destination_port_range:
        min: 443
        max: 443
```

### Example 3: Debugging Image Selection

**Problem**: Empty images list in Terraform

**Step 1: Research**
```markdown
Context7 Query: "oci_core_images data source troubleshooting empty results"
```

**Step 2: Find Solution**
Common causes:
- Incorrect shape filter
- OS version not available
- Missing compartment_id

**Step 3: Fix**
```hcl
# Add debug output
output "available_images" {
  value = data.oci_core_images.oracle_linux.images[*].display_name
}

# Broaden filters temporarily
filter {
  name   = "operating_system"
  values = ["Oracle Linux"]
}
# Remove shape filter to see all images
```

## Integration with CI/CD Pipeline

### Automated Documentation Checks

Create a script that validates templates against Context7 documentation:

```python
# scripts/validate_templates.py
import context7

def validate_terraform_resource(resource_type, config):
    """Validate Terraform resource against Context7 docs"""
    docs = context7.get_documentation(
        library="oracle/terraform-provider-oci",
        query=f"{resource_type} required parameters"
    )
    
    required_params = docs.extract_required_parameters()
    missing = [p for p in required_params if p not in config]
    
    if missing:
        print(f"Missing required parameters: {missing}")
        return False
    return True
```

### Documentation Generation

Use Context7 to generate template documentation:

```bash
#!/bin/bash
# Generate documentation for all modules used

modules=$(grep -h "oci_" *.tf | grep resource | cut -d'"' -f2 | sort -u)

for module in $modules; do
    echo "Generating docs for $module"
    context7 query "oracle/terraform-provider-oci" "$module resource" > "docs/resources/$module.md"
done
```

## Troubleshooting Common Issues

### Issue 1: Outdated Syntax

**Symptom**: Terraform/Ansible reports unknown parameter
**Solution**: 
```markdown
Context7 Query: "[resource_name] deprecated parameters migration"
```

### Issue 2: Missing Dependencies

**Symptom**: Resource creation fails with dependency error
**Solution**:
```markdown
Context7 Query: "[resource_name] depends_on requirements"
```

### Issue 3: Authentication Failures

**Symptom**: Provider authentication errors
**Solution**:
```markdown
Context7 Query: "oci provider authentication troubleshooting"
```

## Tips for Effective Context7 Usage

### 1. Build a Query Library

Maintain a list of useful queries:
```markdown
# queries.md
## Terraform OCI
- VCN Setup: "oci_core_vcn with internet gateway complete example"
- Instance: "oci_core_instance free tier shape configuration"
- Images: "oci_core_images oracle linux filter combinations"

## Ansible OCI
- Setup: "oci ansible collection installation requirements"
- Inventory: "oci dynamic inventory plugin example"
- Modules: "oci compute instance lifecycle management"
```

### 2. Create Templates from Examples

When Context7 provides examples, use them as templates:
1. Copy the example
2. Replace placeholder values
3. Add your specific requirements
4. Test incrementally

### 3. Document Your Queries

Keep track of helpful queries and their results:
```yaml
# .context7_cache.yml
queries:
  - query: "oci_core_instance shape_config"
    date: "2024-11-14"
    useful_for: "Configuring flexible shapes"
    key_findings:
      - "memory_in_gbs is required for flex shapes"
      - "ocpus determines CPU count"
```

## Advanced Context7 Patterns

### Pattern 1: Comparative Analysis
```markdown
Query: "oci_core_instance vs oci_compute_instance differences"
Purpose: Understand terraform vs ansible resource management
```

### Pattern 2: Migration Guides
```markdown
Query: "migrate from oci classic to oci terraform provider"
Purpose: Upgrade legacy infrastructure code
```

### Pattern 3: Performance Optimization
```markdown
Query: "oci terraform provider performance best practices"
Purpose: Optimize large-scale deployments
```

## Conclusion

Context7 integration transforms template development from trial-and-error to informed implementation. By following these practices:

1. **Reduce debugging time** by getting correct syntax upfront
2. **Improve template quality** with best practices from documentation
3. **Stay current** with latest provider/module changes
4. **Troubleshoot efficiently** with targeted error resolution

Remember: Context7 is your documentation companion. Use it early and often in your template development workflow.

---

*Last Updated: November 2024*
*Guide Version: 1.0*
