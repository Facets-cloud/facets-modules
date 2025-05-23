# AWS EventBridge Module

## Overview

This module provisions **AWS EventBridge** resources, including **event rules**, **event patterns**, **scheduled rules**, and **target configurations** for a given event bus. It enables event-driven architecture by allowing users to define rules that react to AWS service events or custom application events.

This module supports **AWS** only.

## Configurability

The following parameters can be configured under the `spec` block:

**`event_bus_name`**: 
The name of the event bus where the rules should be created.  
Must be alphanumeric and may contain hyphens (`-`), underscores (`_`), and periods (`.`).  
Maximum length: **256 characters**

**`tags`**
Key-value tags to apply at the **event bus level**.


**`rules`**
A set of named EventBridge rules to create. Each rule key (e.g., `triggerLambdaOnS3Upload`) maps to its configuration object.

**Required Attributes (per rule)**

- **`is_enabled`**:  
  Whether the rule is active or disabled.

- **`description`**:  
  Description of the rule (max 256 characters).

- **`targets`**:  
  A list of targets to invoke when the rule matches. Example targets can be Lambda functions, SQS queues, SNS topics, Step Functions, etc.

**Optional Attributes (per rule)**

- **`schedule_expression`**:  
  Schedule-based trigger for the rule (e.g., `rate(5 minutes)`, `cron(0 20 * * ? *)`).  
  Required if `event_pattern` is not provided.

- **`event_pattern`**:  
  A pattern for matching specific events (e.g., `{"source": ["aws.ec2"]}`).  
  Required if `schedule_expression` is not provided.

- **`tags`**:  
  Key-value tags for the individual rule.

## Usage
When the resource is created:

A new EventBridge rule will be created under the specified event_bus_name.

The rule will be based on either a schedule_expression (for time-based triggers) or an event_pattern (for event-based triggers).

The specified targets will be invoked whenever the rule is triggered.

Optional tags can be applied both at the event bus level and per rule.

Note: Either schedule_expression or event_pattern must be provided for each rule. If both are missing, the rule will be invalid.

