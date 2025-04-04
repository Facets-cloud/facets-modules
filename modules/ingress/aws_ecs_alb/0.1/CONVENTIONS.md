# Facets Module Conventions

This document outlines the conventions for developing a facets Terraform module. It provides guidelines on how to structure and define the module's configuration files, including `module.json`, variables, and local definitions.

## module.json

The `module.json` file is a critical component of the module, defining its metadata and configuration. It includes the following fields:

- **provides**: This field specifies the type of resource the module provides, such as 'mysql' or 'postgres'.
- **flavors**: This field lists the different variations or flavors of the module, such as 'rds', 'k8s', or 'aurora'.
- **supported_clouds**: This field indicates the cloud platforms that the module supports, such as 'aws'.
- **version**: This field defines the version of the module.
- **depends_on**: This field lists any dependencies the module has on other modules or resources.
- **lifecycle**: This field specifies the lifecycle stage of the module, such as 'ENVIRONMENT'.
- **input_type**: This field describes the type of input the module expects, such as 'instance'.
- **composition**: This field provides additional configuration or composition details.
- **is_old**: This boolean field indicates if the module is considered outdated.

## Variables

Variables are defined in the module to allow for customization and configuration. Each variable should have a type and, optionally, a default value. Descriptions should be provided to explain the purpose of each variable. The variables defined in the `aws_ecs_alb` module are:

- **cluster**: Type `any`. Represents the cluster configuration, including details like stack name and cloud provider. The sub-attributes include:
  - **stackName**: The name of the stack associated with the cluster.
  - **id**: A unique identifier for the cluster.
  - **secrets**: A map of secrets associated with the cluster.
  - **commonEnvironmentVariables**: A map of common environment variables for the cluster.
  - **cloud**: The cloud provider for the cluster.

- **cc_metadata**: Type `any`. Holds metadata related to the cloud configuration, such as the tenant's base domain. The sub-attributes include:
  - **tenant_base_domain**: The base domain for the tenant.
  - **tenant_base_domain_id**: The ID associated with the tenant's base domain.

- **instance**: Type `any`, with a default value of `{}`. Represents the JSON input provided by the user in an object form, including specifications and metadata.

- **instance_name**: Type `string`, with a default value of `""`. Specifies the name of the instance.

- **inputs**: Type `any`, with a default value of `{}`. Represents additional inputs required by the module. This is useful for module writers to wire dependencies they are aware of without burdening the end user with providing some values. 

- **environment**: Type `any`, with a default value of `{}`. Contains environment-specific configurations, such as namespace. The sub-attributes include:
  - **namespace**: Specifies the namespace for the environment.
  - **cloud**: Indicates the cloud provider for the environment.
  - **unique_name**: A unique identifier for the environment.
  - **timezone**: The timezone setting for the environment.

## Facets YAML

The `facets.yaml` file is used to define inputs and outputs for the module. It allows module writers to specify dependencies and default values for inputs.

### Spec

The `spec` section in the YAML file defines the JSON schema for the `var.instance` variable passed to the module. This schema outlines the expected structure and properties of the instance configuration, ensuring that the module receives the correct data format and values.

### Inputs

In the `facets.yaml` file, inputs are defined to automatically retrieve necessary details without requiring explicit input from the end user. For example, if a module requires VPC details, the module writer can specify these details as follows:

## Writing New YAML Files

To add support for new resources in Facets, you need to create YAML files with the following components:

1. **Intent, Flavor, and Metadata**:
   - Define the **intent** (e.g., "redis" or "postgres") to represent the type of resource.
   - Specify the **flavor** (e.g., "k8s" or "aurora") for its implementation.
   - Add metadata like **version**, **description**, and **clouds** (supported platforms).

2. **Spec Section**:
   - Define the **spec** properties using JSON Schema for validation.
   - Include fields like `type`, `properties`, `required`, and validation rules (e.g., `enum`, `pattern`).

3. **Sample Section**:
   - Provide a sample configuration to serve as a default template when the resource is created in the UI.

4. **Custom UI Fields**:
   - Use `x-ui-*` fields to customize the behavior and presentation of the resource in the Facets UI.

## Understanding the Spec Section

The **spec** section is a critical part of the YAML file. It uses JSON Schema to define properties, data types, and validation rules, ensuring consistency and clarity.

### Key JSON Schema Elements:

- **type**: Specifies the data type (e.g., `string`, `boolean`, `object`).
- **properties**: Lists the sub-properties of an object.
- **items**: Defines the schema for array elements.
- **title**: Provides a human-readable name for the property.
- **description**: Explains the property's purpose.
- **enum**: Limits values to a predefined set.
- **minimum/maximum**: Sets numerical constraints.
- **pattern**: Uses regular expressions for string validation.
- **required**: Marks mandatory fields.

## Custom UI Fields (x-ui-* Fields)

Facets extends JSON Schema with custom `x-ui-*` fields to enhance the user interface. These fields control the behavior and display of resource properties in the Facets UI.

### Common x-ui-* Fields:

- **x-ui-api-source**: Fetches dynamic data for dropdowns from an API.
- **x-ui-placeholder**: Provides placeholder text in input fields.
- **x-ui-validation**: Adds custom validation rules.
- **x-ui-visible-if**: Toggles visibility based on another field's value.
- **x-ui-order**: Specifies the display order of properties.
- **x-ui-skip**: Hides certain properties from the UI.
- **x-ui-command**: Indicates that the values within an array represent executable commands.
- **x-ui-disable-tooltip**: Provides a message for a disabled tooltip.
- **x-ui-dynamic-enum**: Dynamically generates enum options based on another field.
- **x-ui-error-message**: Custom error message for validation failures.
- **x-ui-lookup-regex**: Defines regex to extract values for API requests.
- **x-ui-no-sort**: Prevents automatic sorting of dropdown options.
- **x-ui-override-disable**: Prevents users from overriding certain properties in the UI.
- **x-ui-overrides-only**: Displays only overridden fields in the UI.
- **x-ui-toggle**: Renders a property as a toggle switch.
- **x-ui-yaml-editor**: Enables YAML editor for complex structured inputs.

By following these conventions, you can create robust YAML definitions for custom resources in the Facets platform, ensuring consistency, usability, and compliance with platform standards.
