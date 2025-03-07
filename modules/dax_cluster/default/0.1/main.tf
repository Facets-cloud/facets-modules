resource "aws_iam_role" "dax_cluster" {
  name               = "${module.name.name}-dax-cluster-iam-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "dax.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# resource "aws_iam_policy" "dax_policy" {
#   count       = lookup(local.spec, "iam_policies", "") == "" ? 1 : 0
#   name        = "${module.name.name}-dax-policy"
#   description = "Custom policy for DAX cluster"
#   policy      = jsonencode({
#     "Version" : "2012-10-17",
#     "Statement": [
#         {
#             "Action": [
#                 "dynamodb:DescribeTable",
#                 "dynamodb:PutItem",
#                 "dynamodb:GetItem",
#                 "dynamodb:UpdateItem",
#                 "dynamodb:DeleteItem",
#                 "dynamodb:Query",
#                 "dynamodb:Scan",
#                 "dynamodb:BatchGetItem",
#                 "dynamodb:BatchWriteItem",
#                 "dynamodb:ConditionCheckItem"
#             ],
#             "Effect": "Allow",
#             "Resource" : "*"
#         }
#     ]
#   })
# }

resource "aws_iam_policy_attachment" "dax_cluster" {
  name       = "${module.name.name}-iam-policy-attachment"
  policy_arn = lookup(local.spec, "iam_policies", "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess")
  roles      = [aws_iam_role.dax_cluster.name]
}

resource "aws_dax_cluster" "dax_cluster" {
  cluster_name                     = "dax-${substr(module.name.name, 0, 15)}"
  iam_role_arn                     = aws_iam_role.dax_cluster.arn
  node_type                        = local.node_type
  replication_factor               = local.spec.replication_factor
  cluster_endpoint_encryption_type = lookup(local.advanced, "cluster_endpoint_encryption_type", "NONE")
  availability_zones               = lookup(local.advanced, "availability_zones", [])
  description                      = lookup(local.advanced, "description", "")
  notification_topic_arn           = lookup(local.advanced, "notification_topic_arn", "")
  parameter_group_name             = aws_dax_parameter_group.dax_parameter_group.name
  maintenance_window               = lookup(local.advanced, "maintenance_window", "")
  security_group_ids               = concat([aws_security_group.dax_security_group.id], [aws_security_group.additional_dax_security_group.id])
  server_side_encryption {
    enabled = lookup(lookup(local.advanced, "server_side_encryption", {}), "enabled", false)
  }
  subnet_group_name = aws_dax_subnet_group.dax_subnet_group.name
  tags              = merge(local.tags, var.environment.cloud_tags)
}

resource "aws_dax_parameter_group" "dax_parameter_group" {
  name        = "${module.name.name}-parameter-group"
  description = "parameter group for dax cluster"
  dynamic "parameters" {
    for_each = lookup(local.advanced, "parameter_group", {})
    content {
      name  = parameters.value.name
      value = parameters.value.value
    }
  }
}

resource "aws_dax_subnet_group" "dax_subnet_group" {
  name       = "${module.name.name}-subnet-group"
  subnet_ids = var.inputs.network_details.attributes.legacy_outputs.vpc_details.private_subnet_objects.id
}

resource "aws_security_group" "dax_security_group" {
  name        = "dax-${module.name.name}-securitygroup"
  vpc_id      = var.inputs.network_details.attributes.legacy_outputs.vpc_details.vpc_id
  description = lookup(local.aws_security_group, "description", "Security Group for dax cluster")
  tags        = merge(local.tags, var.environment.cloud_tags)
  ingress {
    from_port   = 8111
    protocol    = "tcp"
    to_port     = 8111
    cidr_blocks = local.vpcCIDR
    description = "Allowing inbound traffic to dax cluster"
  }
}

resource "aws_security_group" "additional_dax_security_group" {
  name        = "additional-dax-${module.name.name}-securitygroup"
  vpc_id      = var.inputs.network_details.attributes.legacy_outputs.vpc_details.vpc_id
  description = lookup(local.aws_security_group, "description", "Security Group for dax cluster")
  tags        = merge(local.tags, var.environment.cloud_tags)
  dynamic "ingress" {
    for_each = local.cidr_blocks
    content {
      from_port   = 8111
      protocol    = "tcp"
      to_port     = 8111
      cidr_blocks = [ingress.value]
      description = "Allowing inbound traffic to dax cluster"
    }
  }
}

module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  is_k8s          = false
  globally_unique = false
  resource_type   = "dax_cluster"
  resource_name   = var.instance_name
  environment     = var.environment
  limit           = 20
}
