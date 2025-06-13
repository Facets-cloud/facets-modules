locals {
  # Extract configuration from Facets instance
  spec = var.instance.spec

  # Extract input dependencies
  kubernetes_cluster = var.inputs.kubernetes_cluster
  network_details    = var.inputs.network_details

  # Extract user configuration with defaults
  name                  = try(local.spec.name, "custom-nodepool")
  instance_requirements = try(local.spec.instance_requirements, {})
  scaling               = try(local.spec.scaling, {})
  networking            = try(local.spec.networking, {})
  storage               = try(local.spec.storage, {})
  scheduling            = try(local.spec.scheduling, {})
  tags                  = try(local.spec.tags, {})

  # Generate unique names for resources
  node_class_name = "${local.name}-nodeclass"
  node_pool_name  = "${local.name}-nodepool"

  # Parse comma-separated values into lists with defaults
  instance_families_list = split(",", try(local.instance_requirements.instance_families, "c5,c6i,m5,m6i,r5,r6i"))
  cpu_range_list         = split(",", try(local.instance_requirements.cpu_range, "2,4,8,16"))
  architectures_list     = split(",", try(local.instance_requirements.architectures, "x86_64,arm64"))
  capacity_types_list    = split(",", try(local.instance_requirements.capacity_types, "spot,on-demand"))

  # Handle availability zones - use VPC zones if not specified
  availability_zones_list = try(local.instance_requirements.availability_zones, "") != "" ? split(",", local.instance_requirements.availability_zones) : local.network_details.attributes.availability_zones

  # Parse proxy bypass domains
  proxy_bypass_list = try(local.networking.proxy_configuration.bypass_domains, "") != "" ? split(",", local.networking.proxy_configuration.bypass_domains) : split(",", "localhost,127.0.0.1,169.254.169.254,.internal,.eks.amazonaws.com")

  # Automatically detect IAM role from EKS cluster - updated path for new structure
  node_iam_role_arn = local.kubernetes_cluster.attributes.node_group.iam_role_name

  # Subnet selection based on user choice from dropdown
  subnet_type = try(local.networking.subnet_type, "private")

  # Map subnet type to actual subnet IDs from network output
  subnet_ids_map = {
    private  = local.network_details.attributes.private_subnet_ids
    public   = local.network_details.attributes.public_subnet_ids
    database = local.network_details.attributes.database_subnet_ids
  }

  # Build subnet selector terms using selected subnet type
  subnet_selector_terms = [
    for subnet_id in local.subnet_ids_map[local.subnet_type] : {
      id = subnet_id
    }
  ]

  # Always use the node security group ID from EKS cluster output
  node_security_group_id = local.kubernetes_cluster.attributes.node_group.security_group_id

  # Combine user tags with environment tags - updated cluster name path
  combined_tags = merge(
    local.tags,
    {
      "facets.cloud/environment" = var.environment.name
      "facets.cloud/managed-by"  = "facets"
      # "kubernetes.io/cluster/${local.kubernetes_cluster.attributes.cluster.name}" = "owned"
    }
  )

  # Build node taints from taints configurations
  node_taints = [
    for taint_name, taint_config in try(local.scheduling.taints, {}) : {
      key    = taint_config.key
      value  = taint_config.value
      effect = taint_config.effect
    }
  ]

  # Extract taints and labels for output
  taints = local.node_taints
  labels = merge(
    try(local.scheduling.node_labels, {}),
    {
      "facets.cloud/nodepool"    = local.name
      "facets.cloud/environment" = var.environment.name
    }
  )

  # Proxy userdata script
  proxy_userdata = try(local.networking.proxy_configuration.https_proxy, "") != "" ? base64encode(<<-EOF
    #!/bin/bash
    
    # Configure proxy settings for EKS nodes
    echo "Configuring proxy settings..."
    
    # Set proxy environment variables
    export HTTPS_PROXY="${local.networking.proxy_configuration.https_proxy}"
    export https_proxy="${local.networking.proxy_configuration.https_proxy}"
    export NO_PROXY="${join(",", local.proxy_bypass_list)}"
    export no_proxy="${join(",", local.proxy_bypass_list)}"
    
    # Configure containerd proxy settings
    mkdir -p /etc/systemd/system/containerd.service.d
    cat > /etc/systemd/system/containerd.service.d/proxy.conf << 'PROXY_EOF'
    [Service]
    Environment="HTTPS_PROXY=${local.networking.proxy_configuration.https_proxy}"
    Environment="NO_PROXY=${join(",", local.proxy_bypass_list)}"
    PROXY_EOF
    
    # Configure kubelet proxy settings
    mkdir -p /etc/systemd/system/kubelet.service.d
    cat > /etc/systemd/system/kubelet.service.d/proxy.conf << 'PROXY_EOF'
    [Service]
    Environment="HTTPS_PROXY=${local.networking.proxy_configuration.https_proxy}"
    Environment="NO_PROXY=${join(",", local.proxy_bypass_list)}"
    PROXY_EOF
    
    # Reload systemd and restart services
    systemctl daemon-reload
    systemctl restart containerd
    systemctl restart kubelet
    
    echo "Proxy configuration completed"
    EOF
  ) : null

  # NodeClass manifest
  node_class_manifest = {
    apiVersion = "eks.amazonaws.com/v1"
    kind       = "NodeClass"
    metadata = {
      name = local.node_class_name
    }
    spec = merge(
      {
        # IAM role automatically detected from EKS cluster
        role = local.node_iam_role_arn

        # Use the smart subnet selector terms
        subnetSelectorTerms = local.subnet_selector_terms

        # Security group selection - always use node security group ID from EKS cluster
        securityGroupSelectorTerms = [
          {
            id = local.node_security_group_id
          }
        ]

        # Networking policies for EKS Auto Mode
        snatPolicy             = "Random"
        networkPolicy          = "DefaultAllow"
        networkPolicyEventLogs = "Disabled"

        # Ephemeral storage configuration
        ephemeralStorage = merge(
          {
            size       = try(local.storage.disk_size, "80Gi")
            iops       = try(local.storage.disk_iops, 3000)
            throughput = try(local.storage.disk_throughput, 125)
          },
          try(local.storage.encryption_key, "") != "" ? {
            kmsKeyID = local.storage.encryption_key
          } : {}
        )

        # Instance tags
        tags = local.combined_tags
      },
      # Add proxy configuration if specified - using EKS Auto Mode format
      try(local.networking.proxy_configuration.https_proxy, "") != "" ? {
        advancedNetworking = {
          httpsProxy = local.networking.proxy_configuration.https_proxy
          noProxy    = local.proxy_bypass_list
        }
      } : {}
    )
  }

  # NodePool manifest
  node_pool_manifest = {
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata = {
      name = local.node_pool_name
    }
    spec = {
      # Reference to NodeClass
      template = {
        metadata = {
          labels = merge(
            try(local.scheduling.node_labels, {}),
            {
              "facets.cloud/nodepool"    = local.name
              "facets.cloud/environment" = var.environment.name
            }
          )
          annotations = {
            "facets.cloud/managed-by" = "facets"
          }
        }
        spec = merge(
          {
            # Node class reference
            nodeClassRef = {
              group = "eks.amazonaws.com"
              kind  = "NodeClass"
              name  = local.node_class_name
            }

            # Instance requirements
            requirements = concat(
              local.use_instance_family ? [
                {
                  key      = "eks.amazonaws.com/instance-category"
                  operator = "In"
                  values   = [local.instance_family]
                }
                ] : [
                {
                  key      = "node.kubernetes.io/instance-type"
                  operator = "In"
                  values   = [local.instance_type]
                }
              ],
              # CPU requirements
              [
                {
                  key      = "eks.amazonaws.com/instance-cpu"
                  operator = "In"
                  values   = local.cpu_range_list
                }
              ],
              # Architecture requirements
              [
                {
                  key      = "kubernetes.io/arch"
                  operator = "In"
                  values   = local.architectures_list
                }
              ],
              # Capacity type requirements
              [
                {
                  key      = "karpenter.sh/capacity-type"
                  operator = "In"
                  values   = local.capacity_types_list
                }
              ],
              # Availability zone requirements
              length(local.availability_zones_list) > 0 ? [
                {
                  key      = "topology.kubernetes.io/zone"
                  operator = "In"
                  values   = local.availability_zones_list
                }
              ] : []
            )
          },
          length(local.node_taints) > 0 ? {
            taints = local.node_taints
          } : {}
        )
      }

      # Disruption configuration
      disruption = {
        consolidationPolicy = try(local.scaling.consolidation_policy, "WhenEmptyOrUnderutilized")
        consolidateAfter    = try(local.scaling.consolidation_delay, "30s")
      }

      # Resource limits
      limits = {
        cpu    = try(local.scaling.max_cpu, "1000")
        memory = try(local.scaling.max_memory, "1000Gi")
      }
    }
  }

  use_instance_family = try(local.instance_requirements.use_instance_family, true)
  instance_family     = try(local.instance_requirements.instance_family, "c")
  instance_type       = try(local.instance_requirements.instance_type, "m6i.large")
}
