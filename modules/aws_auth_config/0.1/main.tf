data "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
}

locals {
  existing_map_roles = yamldecode(data.kubernetes_config_map.aws_auth.data["mapRoles"])
  existing_map_users = yamldecode(data.kubernetes_config_map.aws_auth.data["mapUsers"])

  # Convert existing roles and users to maps with ARN as the key
  existing_roles_map = { for role in local.existing_map_roles : role.rolearn => role }
  existing_users_map = { for user in local.existing_map_users : user.userarn => user }

  # Convert new roles and users to maps with ARN as the key
  new_roles_map = { for role in lookup(var.instance.spec, "map_roles", {}) : role.rolearn => {
    rolearn  = role.rolearn
    username = role.username
    groups   = [for group in role.groups : group.name]
  }}

  new_users_map = { for user in lookup(var.instance.spec, "map_users", {}) : user.userarn => {
    userarn  = user.userarn
    username = user.username
    groups   = [for group in user.groups : group.name]
  }}

  # Merge the maps, preferring new entries over existing ones
  merged_roles_map = merge(local.existing_roles_map, local.new_roles_map)
  merged_users_map = merge(local.existing_users_map, local.new_users_map)

  # Convert the merged maps back to lists
  merged_map_roles = [for role in local.merged_roles_map : {
    rolearn  = role.rolearn
    username = role.username
    groups   = role.groups
  }]

  merged_map_users = [for user in local.merged_users_map : {
    userarn  = user.userarn
    username = user.username
    groups   = user.groups
  }]

  updated_data = {
    mapRoles = yamlencode(local.merged_map_roles)
    mapUsers = yamlencode(local.merged_map_users)
  }
}

resource "kubernetes_config_map_v1_data" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  force = true
  data  = local.updated_data
}
