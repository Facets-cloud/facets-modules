# Datastore Module Standards

These instructions supplement the default Facets module generation guidelines for this repository.

## Repository Scope

This repository contains modules for databases, caches, queues, and their various flavors. Each module represents a specific technology (e.g., `postgres`, `redis`, `rabbitmq`).

## Design Philosophy

### Simplicity Over Flexibility
- Provide common functionalities with sensible defaults
- Do NOT expose every possible configuration option  
- Use secure, production-ready defaults that don't require configuration
- Users can fork the repository for custom configurations

### Technology-Familiar Field Names
- Use field names familiar to users of the underlying technology
- Do NOT invent new abstractions or terms
- Make modules configurable by developers who are not cloud experts
- Do NOT expose low-level cloud details (subnet groups, security groups, credentials)
- Generate necessary infrastructure components within the module
- **FORBIDDEN**: Do NOT add Ops-centric fields (monitoring, alerting, backup schedules, log retention, networking configs)
- **ALWAYS use developer-centric abstraction** - simple, intuitive inputs focused on what developers need (never ops-centric)

### Security-First Defaults
- Always configure secure, production-ready defaults (hardcoded, not configurable)
- Enable encryption at rest and in transit automatically
- Enable high availability by default
- Configure sensible backup policies automatically (7 days retention)
- Follow principle of least privilege for access

## Module Conventions

### Naming Standards
- **Intent**: Use only the technology name (e.g., `postgres`, `redis`, `kafka`)
- **Flavors**: Represent variants or configurations (e.g., `ha`, `secure`, `basic`)
- **Name Length Limits**: Ensure generated resource names comply with cloud provider and Kubernetes naming constraints (63 characters max)

- **All outputs and inputs MUST use `@facets/` namespace prefix**
- **STRICTLY FORBIDDEN: Using any output types that do NOT start with `@facets/` (e.g., `@outputs/`, `@modules/`, etc.)**

## Core Functionality Requirements

Every module MUST provide support for:

1. **Version Management**
   - Support only the last 3 major versions of each technology
   - Do NOT support deprecated versions
   - Default to latest supported version
   - **MANDATORY: Validate version options against cloud provider documentation** - ensure all enum values are actually supported by the target cloud provider

2. **Authentication & Security**
   - Secure credential management
   - Access control configuration
   - Integration with identity providers where applicable

3. **Sizing & Performance**
   - Performance-based instance sizing
   - Storage capacity configuration
   - Resource scaling options

4. **Backup & Restore** (Essential)
   - Automated backup configuration with sensible defaults (not configurable)
   - **MUST support restore from backup functionality**
   - Point-in-time recovery options where supported by technology

5. **Import Support**
   - MUST support importing existing resources
   - Include import declarations in facets.yaml
   - Use `discover_terraform_resources()` and `add_import_declaration()`

## Module Structure

### Required Files
```
technology-name/
├── facets.yaml          # Must include @facets/ outputs and import declarations
├── main.tf             # Core Terraform resources
├── variables.tf        # Must mirror facets.yaml spec structure
├── locals.tf           # Local computations and output_attributes
└── README.md           # Generated documentation
```

### Import Configuration
After implementing the fundamental module:
1. Discuss with user which resources to support import for
2. Run `discover_terraform_resources(module_path)` to identify resources
3. Add import declarations for essential resources with user confirmation
4. **Import tool parameters**: Use `module_path`, `name` (field name from spec->imports), `resource_address`, and `required` fields only
5. **Ignore these parameters**: Set `resource`, `index`, and `key` to None (do not use them)
6. **Prevent unwanted recreates**: For imported resources, evaluate adding `ignore_changes` for attributes that would trigger recreation (e.g., subnet groups, VPC settings) since changing these genuinely requires delete/recreate anyway

## CRITICAL: Input Type Management Rules

**NEVER register output types that you need as inputs:**
- ALL required input types MUST already exist in the control plane
- If needed input types don't exist, STOP and clarify with the user first
- Do NOT create missing input types - they must be provided by other modules

## Output Types and Structure

### MANDATORY User Approval for New Output Types
- Get explicit user confirmation before creating ANY new output type
- There is NO blanket approval for output type creation
- Present the output type structure and get approval before proceeding

### Output Naming Convention
- **Default output**: Use flavor-specific name (e.g., `@facets/rds`, `@facets/redis-cluster`, `@facets/kafka-ha`)
- **Interfaces output**: Use generic technology name (e.g., `@facets/postgres-interface`, `@facets/redis-interface`, `@facets/kafka-interface`)
- This allows different flavors to provide the same interface type for cross-flavor compatibility

### Interface Structure
All modules of the same intent MUST maintain consistency in their `interfaces` output structure.

**Reader/Writer Datastores:**
```yaml
output_interfaces = {
  writer = {
    host = "<writer_endpoint>"
    username = "<username>"
    password = "<password>"
    connection_string = "<protocol>://<username>:<password>@<writer_endpoint>:<port>/<database>"
  }
  reader = {
    host = "<reader_endpoint>"
    username = "<username>"
    password = "<password>"
    connection_string = "<protocol>://<username>:<password>@<reader_endpoint>:<port>/<database>"
  }
}
```

**Clustered Datastores:**
```yaml
output_interfaces = {
  cluster = {
    endpoint = "<host1>:<port>,<host2>:<port>,<host3>:<port>"
    connection_string = "<protocol>://<username>:<password>@<host1>:<port>,<host2>:<port>/<database>"
    username = "<username>"
    password = "<password>"
    endpoints = {
      "0" = "<host1>:<port>"
      "1" = "<host2>:<port>"
      "2" = "<host3>:<port>"
    }
  }
}
```

### Connection String Format
- **Protocol-prefixed**: Use technology-specific prefix (e.g., `mysql://`, `postgres://`, `redis://`)
- **Driver-agnostic**: No JDBC or other driver-specific prefixes
- **Standard format**: `<protocol>://<username>:<password>@<host>:<port>/<database>`

## Spec Structure

All modules MUST organize their `spec.properties` using **GROUPED OBJECTS**, not flat fields. **STRICTLY FORBIDDEN** to create flat spec structures or deviate from this grouping:

### Required Grouping Structure
```yaml
spec:
  properties:
    version_config:
      type: object
      title: "Version & Basic Configuration"
      properties:
        version:
          type: string
          title: "Database Version"
          description: "Version of the database engine"
          enum: ["13", "14", "15"]  # Only last 3 major versions - MUST validate against cloud provider docs
          default: "15"  # Always default to latest
        # engine_variant: (if applicable for technology)
    
    sizing:
      type: object
      title: "Sizing & Performance"
      properties:
        instance_class:
          type: string
          title: "Instance Class"
          description: "Database instance class"
          enum: ["db.t3.micro", "db.t3.small", "db.t3.medium", "db.m5.large"]
          default: "db.t3.small"
        
        allocated_storage:
          type: number
          title: "Allocated Storage (GB)"
          description: "Initial storage allocation in GB"
          minimum: 20
          default: 100
          
        read_replica_count:
          type: number
          title: "Read Replica Count"
          description: "Number of read replicas to create"
          minimum: 0
          maximum: 5
          default: 0
    
    restore_config:
      type: object
      title: "Restore Operations"
      properties:
        restore_from_backup:
          type: boolean
          title: "Restore from Backup"
          description: "Restore database from existing backup"
          default: false
        
        source_db_instance_identifier:
          type: string
          title: "Source DB Instance"
          description: "Source database instance identifier for restore"
          x-ui-visible-if:
            field: spec.restore_config.restore_from_backup
            values: [true]
        
        # IMPORTANT: If the technology requires explicit credentials for restore,
        # add master_username and master_password fields here (both conditional on restore_from_backup)
        # Many databases cannot generate new credentials when restoring from backup
    
    imports:
      type: object
      title: "Import Existing Resources"
      properties:
        # Field names MUST match terraform import requirements (e.g., db_instance_arn, cluster_id, etc.)
        # These field names will be passed as the 'name' parameter to import tools
        # Example fields (customize per technology):
        # db_instance_arn: (string) for importing RDS instances
        # cluster_identifier: (string) for importing clusters
        # Use technology-appropriate identifiers required by terraform import

# Note: Backup retention, encryption, HA are hardcoded (not configurable)
# - Backup retention: 7 days
# - Encryption: Always enabled  
# - Multi-AZ/HA: Enabled by default
```

### Forbidden Fields
**DO NOT include any of these Ops-centric fields:**
- Monitoring configurations (CloudWatch, metrics, dashboards)
- Alerting settings (SNS topics, alarm thresholds)
- Backup schedules or retention policies (auto-configured)
- Log retention or log group settings
- Networking details (VPC, subnets, security groups)
- Maintenance windows or update policies
- Auto-scaling configurations
- Performance insights or enhanced monitoring

## Development Workflow

When using `generate_module_with_user_confirmation` to present module plans, ensure the following requirements are met:

### Pre-Planning Requirements
**BEFORE presenting any module plan with generate_module_with_user_confirmation:**
1. **Fetch existing output types** using appropriate tools to understand what `@facets/` types are already available for inputs
2. **IGNORE any output types that do NOT start with `@facets/` - only consider `@facets/` prefixed types**
3. **CRITICAL: NEVER register output types that you need as inputs** - ALL required input types MUST already exist. If needed input types don't exist, STOP and clarify with the user first.
4. **Determine new output types** this module will create (both default and interfaces outputs)
5. **MANDATORY: Get explicit user approval** for ANY new output types before proceeding - there is NO blanket approval for creating output types
6. **Verify type compatibility** across flavors of the same technology
7. **Identify ALL required provider inputs** to ensure sufficient cloud provider configurations are available (e.g., AWS, GCP, Azure providers)

### Required Plan Elements
**Module plan presented with generate_module_with_user_confirmation MUST include:**

**Spec Structure (Grouped Objects):**
- `version_config`: version fields and basic configuration
- `sizing`: performance and storage configuration
- `restore_config`: backup restore operations (include credential fields if technology requires them)
- `imports`: import existing resources (field names must match terraform import requirements like ARN, resource ID, etc.)

**Input Requirements:**
- Provider inputs (MANDATORY): `@facets/aws-provider`, etc.
- Infrastructure inputs: `@facets/vpc`, other needed `@facets/` types
- **STRICTLY FORBIDDEN**: Using any non-`@facets/` prefixed types

**Output Types:**
- Default output: `@facets/[flavor-specific-name]` (mark NEW/REUSED)
- Interfaces output: `@facets/[technology]-interface` (mark NEW/REUSED)
- **CRITICAL**: ALL output types MUST start with `@facets/`

## Validation Checklist

Before completing any module:
- [ ] Generated resource names comply with 63 character limits
- [ ] Only last 3 major versions supported
- [ ] Version options validated against cloud provider documentation
- [ ] Outputs use `@facets/` namespace
- [ ] Inputs only consume `@facets/` namespaced types
- [ ] Import declarations included for major resources
- [ ] Restore from backup functionality implemented and tested
- [ ] Security defaults hardcoded (encryption, HA, backup policies)
- [ ] Credentials, subnet groups, security groups auto-generated
- [ ] Standardized interfaces output structure implemented
- [ ] **Spec uses GROUPED OBJECTS structure (version_config, sizing, restore_config) - NOT flat fields**
- [ ] **NO Ops-centric fields included (monitoring, alerting, backup schedules, networking configs)**
- [ ] Module validates successfully with `validate_module()`