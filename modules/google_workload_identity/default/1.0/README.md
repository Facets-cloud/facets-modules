# terraform-google-workload-identity

[`Workload Identity`](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) is the recommended way to access GCP services from Kubernetes.

This resource creates:

* IAM Service Account binding to `roles/iam.workloadIdentityUser`
* Optionally, a Google Service Account
* Optionally, a Kubernetes Service Account

## Usage

This resource can create service accounts for you,
or you can use existing accounts; this applies for both the Google and
Kubernetes accounts.

### Creating a Workload Identity

```json
{
  "kind": "google_workload_identity",
  "flavor": "default",
  "version": "1.0",
  "disabled": true,
  "spec": {
    "name": "petclinic",
    "gcp_sa_name": "petclinic",
    "use_existing_gcp_sa": false,
    "gcp_sa_description": "GCP Service Account for petclinic application",
    "gcp_sa_create_ignore_already_exists": false,
    "k8s_sa_name": "petclinic-sa",
    "use_existing_k8s_sa": false,
    "namespace": "default",
    "roles": {
      "storage-admin": {
        "role": "roles/storage.admin"
      },
      "compute-admin": {
        "role": "roles/compute.admin"
      }
    }
  }
}
```

This will create:

* Google Service Account named: `gcp_sa_name@gcp-project-name.iam.gserviceaccount.com`
* Kubernetes Service Account named: `k8s_sa_name` in the `default` namespace
* IAM Binding (`roles/iam.workloadIdentityUser`) between the service accounts

Usage from a Kubernetes deployment:

```yaml
metadata:
  namespace: default
  # ...
spec:
  # ...
  template:
    spec:
      serviceAccountName: k8s_sa_name
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name                                     | Description                                                                                                                                                    | Type                | Default     | Required |
| ---------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | ----------- | :------: |
| annotate\_k8s\_sa                        | Annotate the kubernetes service account with 'iam.gke.io/gcp-service-account' annotation. Valid in cases when an existing SA is used.                          | `bool`              | `true`      |    no    |
| automount\_service\_account\_token       | Enable automatic mounting of the service account token                                                                                                         | `bool`              | `false`     |    no    |
| gcp\_sa\_create\_ignore\_already\_exists | If set to true, skip service account creation if a service account with the same email already exists.                                                         | `bool`              | `null`      |    no    |
| gcp\_sa\_description                     | The Service Google service account desciption; if null, will be left out                                                                                       | `string`            | `null`      |    no    |
| gcp\_sa\_name                            | Name for the Google service account; overrides `var.name`.                                                                                                     | `string`            | `null`      |    no    |
| k8s\_sa\_name                            | Name for the Kubernetes service account; overrides `var.name`. `cluster_name` and `location` must be set when this input is specified.                         | `string`            | `null`      |    no    |
| name                                     | Name for both service accounts. The GCP SA will be truncated to the first 30 chars if necessary.                                                               | `string`            | n/a         |   yes    |
| namespace                                | Namespace for the Kubernetes service account                                                                                                                   | `string`            | `"default"` |    no    |
| project\_id                              | GCP project ID                                                                                                                                                 | `string`            | n/a         |   yes    |
| roles                                    | A map of key to role object to be added to the created service account                                                                                                     | `map(string)`      | `null`        |    yes    |
| use\_existing\_gcp\_sa                   | Use an existing Google service account instead of creating one                                                                                                 | `bool`              | `false`     |    no    |
| use\_existing\_k8s\_sa                   | Use an existing kubernetes service account instead of creating one                                                                                             | `bool`              | `false`     |    no    |

## Outputs

| Name                             | Description                           |
| -------------------------------- | ------------------------------------- |
| gcp\_sa\_email     | Email address of GCP service account. |
| gcp\_sa\_fqn       | FQN of GCP service account.           |
| gcp\_sa\_name      | Name of GCP service account.          |
| k8s\_sa\_name      | Name of k8s service account.          |
| k8s\_sa\_namespace | Namespace of k8s service account.     |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->