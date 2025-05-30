locals {
  output_interfaces = {}
  output_attributes = {
    file_system_id     = aws_efs_file_system.efs-csi-driver.id
    storage_class_name = local.instance_name
  }
}
