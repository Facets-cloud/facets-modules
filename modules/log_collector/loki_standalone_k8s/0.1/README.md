# Terraform Log Collector Module

This folder contains a Log Collector Terraform module that deploys kubernetes objects to monitor logs from application.

## Run this module manually

- `cd test`
- Make sure you pass the right kubernetes config path in [provider.tf](test/providers.tf)
- Run `terraform init`
- Run `terraform apply`
  - **Note:** _Optional flag `-auto-approve` to skip interactive approval of plan before applying_
- When you're done, run `terraform destroy`
  - **Note:** _Optional flag `-auto-approve` to skip interactive approval of plan before destroying_

## Running automated tests against this module

- `cd test`
- Make sure to update values in var block inside go [test file](test/log_collector_test.go)
- Run `go test -v -run TestLogCollector`
