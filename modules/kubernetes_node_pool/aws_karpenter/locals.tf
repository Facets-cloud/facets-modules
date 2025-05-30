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

  # Map disk types to AWS EBS configurations
  disk_type_mapping = {
    "gp3-standard"          = { type = "gp3", iops = 3000, throughput = 125 }
    "gp3-high-performance"  = { type = "gp3", iops = 10000, throughput = 500 }
    "io2-ultra-performance" = { type = "io2", iops = 16000, throughput = 1000 }
  }

  disk_config = local.disk_type_mapping[try(local.storage.disk_type, "gp3-standard")]

  # Automatically detect IAM role from EKS cluster - updated path for new structure
  node_iam_role_arn = local.kubernetes_cluster.attributes.node_group.iam_role_arn

  # Build subnet selector based on user configuration or smart defaults
  subnet_selector_tags = length(try(local.networking.subnet_selection, {})) > 0 ? local.networking.subnet_selection : {
    "kubernetes.io/role/internal-elb" = "1"
    "tier"                            = "private"
  }

  # Build security group selector based on user configuration or smart defaults - updated cluster name path
  security_group_selector_tags = length(try(local.networking.security_group_selection, {})) > 0 ? local.networking.security_group_selection : {
    "aws:eks:cluster-name" = local.kubernetes_cluster.attributes.cluster.name
  }

  # Combine user tags with environment tags - updated cluster name path
  combined_tags = merge(
    local.tags,
    {
      "facets.cloud/environment"                                                  = var.environment
      "facets.cloud/managed-by"                                                   = "facets"
      "kubernetes.io/cluster/${local.kubernetes_cluster.attributes.cluster.name}" = "owned"
    }
  )

  # Build node taints from workload_isolation configurations
  node_taints = [
    for taint_name, taint_config in try(local.scheduling.workload_isolation, {}) : {
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
      "facets.cloud/environment" = var.environment
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
    apiVersion = "karpenter.k8s.aws/v1beta1"
    kind       = "EC2NodeClass"
    metadata = {
      name      = local.node_class_name
      namespace = "karpenter"
    }
    spec = merge(
      {
        # IAM role automatically detected from EKS cluster
        role = local.node_iam_role_arn

        # Subnet selection
        subnetSelectorTerms = [
          {
            tags = local.subnet_selector_tags
          }
        ]

        # Security group selection
        securityGroupSelectorTerms = [
          {
            tags = local.security_group_selector_tags
          }
        ]

        # Storage configuration
        blockDeviceMappings = [
          {
            deviceName = "/dev/xvda"
            ebs = merge(
              {
                volumeSize          = try(local.storage.disk_size, "80Gi")
                volumeType          = local.disk_config.type
                iops                = local.disk_config.iops
                throughput          = local.disk_config.throughput
                deleteOnTermination = true
                encrypted           = true
              },
              try(local.storage.encryption_key, "") != "" ? {
                kmsKeyID = local.storage.encryption_key
              } : {}
            )
          }
        ]

        # Networking policies for EKS Auto Mode
        snatPolicy             = "Random"
        networkPolicy          = "DefaultAllow"
        networkPolicyEventLogs = "Disabled"

        # Instance tags
        tags = local.combined_tags
      },
      # Add proxy configuration if specified
      local.proxy_userdata != null ? {
        userData = local.proxy_userdata
      } : {}
    )
  }

  # NodePool manifest
  node_pool_manifest = {
    apiVersion = "karpenter.sh/v1beta1"
    kind       = "NodePool"
    metadata = {
      name      = local.node_pool_name
      namespace = "karpenter"
    }
    spec = {
      # Reference to NodeClass
      template = {
        metadata = {
          labels = merge(
            try(local.scheduling.node_labels, {}),
            {
              "facets.cloud/nodepool"    = local.name
              "facets.cloud/environment" = var.environment
            }
          )
          annotations = {
            "facets.cloud/managed-by" = "facets"
          }
        }
        spec = merge(
          {
            # NodeClass reference
            nodeClassRef = {
              apiVersion = "karpenter.k8s.aws/v1beta1"
              kind       = "EC2NodeClass"
              name       = local.node_class_name
            }

            # Instance requirements
            requirements = concat(
              [
                {
                  key      = "karpenter.k8s.aws/instance-category"
                  operator = "In"
                  values   = local.instance_families_list
                },
                {
                  key      = "karpenter.k8s.aws/instance-cpu"
                  operator = "In"
                  values   = local.cpu_range_list
                },
                {
                  key      = "kubernetes.io/arch"
                  operator = "In"
                  values   = local.architectures_list
                },
                {
                  key      = "karpenter.sh/capacity-type"
                  operator = "In"
                  values   = local.capacity_types_list
                }
              ],
              length(local.availability_zones_list) > 0 ? [
                {
                  key      = "topology.kubernetes.io/zone"
                  operator = "In"
                  values   = local.availability_zones_list
                }
              ] : []
            )
          },
          # Add taints if workload isolation is enabled
          length(local.node_taints) > 0 ? {
            taints = local.node_taints
          } : {}
        )
      }

      # Resource limits
      limits = {
        cpu    = try(local.scaling.max_cpu, "1000")
        memory = try(local.scaling.max_memory, "1000Gi")
      }

      # Disruption settings for cost optimization
      disruption = {
        consolidationPolicy = try(local.scaling.consolidation_policy, "WhenEmptyOrUnderutilized")
        consolidateAfter    = try(local.scaling.consolidation_delay, "30s")
      }
    }
  }

  # Combined manifests for output
  all_manifests = [
    local.node_class_manifest,
    local.node_pool_manifest
  ]
}
