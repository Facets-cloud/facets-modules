# Introduction

DynamoDB Accelerator (DAX) is an in-memory cache for Amazon DynamoDB which is fully managed and is highly available.

## Properties

| Property     | Type            | Required | Description                                                                                                                                    |
| ------------ | --------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| `flavor`     | string          | **Yes**  | Implementation selector for the resource. e.g. for a resource type ingress, default, aws_alb, gcp_alb etc.                                     |
| `kind`       | string          | **Yes**  | Describes the type of resource. e.g. ingress, application, mysql etc. If not specified, fallback is the `folder_name`/instances                |
| `metadata`   | object          | **Yes**  | Metadata related to the resource                                                                                                               |
| `spec`       | [object](#spec) | **Yes**  | Specification as per resource types schema                                                                                                     |
| `version`    | string          | **Yes**  | This field can be used to pin to a particular version                                                                                          |
| `advanced`   | object          | No       | Additional fields if any for a particular implementation of a resource                                                                         |
| `depends_on` |                 | No       | Dependencies on other resources. e.g. application x may depend on mysql                                                                        |
| `disabled`   | boolean         | No       | Flag to disable the resource                                                                                          
| `out`        | [object](#out)  | No       | Output given by the resource for others to refer.                                                                                              |
| `provided`   | boolean         | No       | Flag to tell if the resource should not be provisioned by facets   |
                                        

## Spec

Specification as per resource types schema

### Properties

| Property           | Type   | Required | Description                                                                                                                                                                                                                              |
| ------------------ | ------ | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `size` | object | **Yes**  | The instance type of the node eg: "instance": "dax.r4.large"                                                                                    |
| `replication_factor`     | number | **Yes**  | The number of nodes in the DAX cluster |
| `iam_policies`     | string | **No**  | The iam policy to be attached to iam role created. Defaults to `DynamoDBFullAccess` policy |


## Advanced

Advanced specifications 

| Property           | Type   | Required | Description                                                                                                                                                                                                                              |
| ------------------ | ------ | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cluster_endpoint_encryption_type` | string | **No**  | The type of encryption the cluster's endpoint should support. Valid values are: NONE and TLS                                                                      |
| `availability_zones`     | object | **No**  | List of Availability Zones in which the nodes will be created |
| `description`     | object | **No**  | Description for the cluster |
| `notification_topic_arn`     | string | **No**  | An Amazon Resource Name (ARN) of an SNS topic to send DAX notifications to. Example: arn:aws:sns:us-east-1:012345678999:my_sns_topic |
| `parameter_group`     | object | **No**  | List of parameters to be passed to dax parameter group created |
| `maintenance_window`     | string | **No**  | Specifies the weekly time range for when maintenance on the cluster is performed. eg: "sun:05:00-sun:09:00" |
| `security_group_ids`     | object | **No**  | One or more VPC security groups associated with the cluster |
| `server_side_encryption`     | object | **No**  | Encrypt at rest options |
| `tags`     | object | **No**  | A map of tags to assign to the resource |

## Output 
| Name            | Description                                                          | Datatype | Required |
|-----------------|----------------------------------------------------------------------|----------|----------|
| `configuration_endpoint`   | The configuration endpoint for this DAX cluster, consisting of a DNS name and a port number                                      | string   | No      |
| `cluster_address`    | The DNS name of the DAX cluster without the port appended                                | string   | No      |
| `arn`  | The ARN of the DAX cluster | string      | yes      |
| `port` | The port used by the configuration endpoint                                           | number   | No      |
| `nodes` | List of node objects including id, address, port and availability_zone | object | No |

## Limitations
Instance Name should not be greater than 20 Characters