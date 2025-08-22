# Random String Generator Module

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Clouds](https://img.shields.io/badge/clouds-AWS%20%7C%20GCP%20%7C%20Azure-green)

## Overview

This module generates configurable random strings using a utility module. It provides developers with a simple interface to create random strings with customizable character sets and length requirements for applications that need secure random values.

## Environment as Dimension

This module is environment-agnostic as it generates random strings that are independent of specific cloud environments. The generated strings remain consistent across different deployment environments while being unique per instance.

## Resources Created

- **Random String**: A configurable random string generated using specified parameters
- **String Metadata**: Information about the generated string including length and character set configuration

## Key Features

- **Configurable Length**: Generate strings from 1 to 128 characters
- **Character Set Control**: Fine-grained control over character types (uppercase, lowercase, numeric, special)
- **Multi-cloud Support**: Works consistently across AWS, GCP, and Azure
- **Developer-friendly Interface**: Simple boolean toggles for character set inclusion

## Configuration Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `string_length` | number | 12 | Length of the random string (1-128) |
| `include_special` | boolean | false | Include special characters |
| `include_upper` | boolean | true | Include uppercase letters |
| `include_lower` | boolean | true | Include lowercase letters |
| `include_numeric` | boolean | true | Include numeric characters |

## Outputs

The module exposes a structured output containing:
- Generated random string value
- String length information  
- Character set configuration used
- Resource metadata for tracking

## Security Considerations

- Random strings are generated using cryptographically secure methods
- No sensitive data is logged or persisted outside of Terraform state
- Generated strings should be treated as secrets when used for authentication purposes
