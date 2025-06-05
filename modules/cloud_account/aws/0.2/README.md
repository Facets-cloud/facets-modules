# Cloud Account Module

This module provides a way to use a specific cloud account for creating resources using terraform on AWS. This module also allows users to use custom aws providers in facets cloud by exposing type `@outputs/cloud_account`.

## Functionality

- Provides a way to use a specific AWS cloud account credentials so that it can be used by terraform to create cloud resources.
- Also provides user ability to use custom terraform providers if required.


## Configurability

| Name              | Description                                          | Type   | Default | Required |
| ----------------- | ---------------------------------------------------- | ------ | ------- | -------- |
| region            | AWS region to use for the provider                   | string | n/a     | no       |
| role_arn          | ARN of the role to assume for provider configuration | string | n/a     | yes      |
| role_session_name | Identifier for the assumed role session              | string | n/a     | yes      |
| external_id       | External ID for cross-account role assumption        | string | n/a     | yes      |

## Outputs

| Name         | Description                                                  |
| ------------ | ------------------------------------------------------------ |
| aws_iam_role | The ARN of the assumed role                                  |
| session_name | The identifier for the assumed role session.                 |
| external_id  | The identifier required to assume a role in another account. |
| aws_region   | The AWS Region configured for Terraform AWS Provider         |
