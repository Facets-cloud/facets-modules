module "name" {
  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 64
  globally_unique = true
  resource_name   = local.instance_name
  resource_type   = "aws_efs"
  is_k8s          = false
}

resource "aws_efs_file_system" "efs-csi-driver" {
  tags = merge({
    Name = module.name.name
  }, lookup(local.aws_efs_file_system, "tags", {}), var.environment.cloud_tags)
  creation_token                  = lookup(local.aws_efs_file_system, "creation_token", null)
  encrypted                       = lookup(local.aws_efs_file_system, "encrypted", true)
  kms_key_id                      = lookup(local.aws_efs_file_system, "kms_key_id", null)
  performance_mode                = lookup(local.aws_efs_file_system, "performance_mode", null)
  availability_zone_name          = lookup(local.aws_efs_file_system, "availability_zone_name", null)
  provisioned_throughput_in_mibps = lookup(local.aws_efs_file_system, "provisioned_throughput_in_mibps", null)
  throughput_mode                 = lookup(local.aws_efs_file_system, "throughput_mode", null)
  dynamic "lifecycle_policy" {
    for_each = lookup(local.aws_efs_file_system, "lifecycle_policy", {})
    content {
      transition_to_ia                    = lookup(lifecycle_policy.value, "transition_to_ia", null)
      transition_to_primary_storage_class = lookup(lifecycle_policy.value, "transition_to_primary_storage_class", null)
    }
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_security_group" "efs-csi-driver" {
  name = module.name.name
  ingress {
    from_port   = 2049
    protocol    = "TCP"
    to_port     = 2049
    cidr_blocks = [local.vpc_details.vpc_cidr]
    description = "Inbound Access to the EFS filesystem ${module.name.name}"
  }
  vpc_id = local.vpc_details.vpc_id
}

resource "aws_efs_mount_target" "efs-csi-driver" {
  count           = length(local.vpc_details.private_subnets)
  file_system_id  = aws_efs_file_system.efs-csi-driver.id
  subnet_id       = length(local.vpc_details.private_subnets) > 0 ? local.vpc_details.private_subnets[count.index] : ""
  security_groups = [aws_security_group.efs-csi-driver.id]
}

resource "kubernetes_storage_class" "efs-csi-drive-sc" {
  metadata {
    name = local.instance_name
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "false"
    }
  }
  storage_provisioner = "efs.csi.aws.com"
  mount_options = [
    "tls",
    "iam"
  ]
  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = aws_efs_file_system.efs-csi-driver.id
    directoryPerms   = "700"
  }
  reclaim_policy      = "Delete"
  volume_binding_mode = "Immediate"
}
