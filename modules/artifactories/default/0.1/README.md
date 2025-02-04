# Terraform Artifactories Module

This is a artifactories per instance module

## Run this module manually

- `cd test`
- Make sure you add/update details in [provider.tf](test/providers.tf)
- Run `terraform init`
- Run `terraform apply`
  - **Note:** _Optional flag `-auto-approve` to skip interactive approval of plan before applying_
- When you're done, run `terraform destroy`
  - **Note:** _Optional flag `-auto-approve` to skip interactive approval of plan before destroying_

## Running automated tests against this module

- `cd test`
- Make sure to update `config_path` in var block inside go [test file](test/artifactories_test.go)
- Run `go test -v -run Artifactories`
