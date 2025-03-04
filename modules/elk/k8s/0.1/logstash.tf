locals {
  normalised_clustername = upper(replace("${module.name.name}-eck", "-", "_"))
  default_ilm_policy     = <<-EOT
  {
      "policy": {
          "phases": {
              "hot": {
                  "min_age": "0ms",
                  "actions": {
                      "rollover": {
                          "max_size": "50GB",
                          "max_age": "30d"
                      },
                      "set_priority": {
                          "priority": 100
                      }
                  }
              },
              "warm": {
                  "min_age": "30d",
                  "actions": {
                      "forcemerge": {
                          "max_num_segments": 1
                      },
                      "shrink": {
                          "number_of_shards": 1
                      },
                      "set_priority": {
                          "priority": 50
                      }
                  }
              },
              "cold": {
                  "min_age": "60d",
                  "actions": {
                      "freeze": {},
                      "set_priority": {
                          "priority": 0
                      }
                  }
              },
              "delete": {
                  "min_age": "${lookup(local.spec, "retention", "60d")}",
                  "actions": {
                      "delete": {}
                  }
              }
          }
      }
  }
  EOT

  ilmpolicy_config = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "${module.name.name}-default-ilmpolicy"
      namespace = local.namespace
    }
    data = {
      "ilm-policy.json" = lookup(local.spec, "ilm_policy", local.default_ilm_policy)
    }
  }
  filebeat_config = {
    apiVersion = "beat.k8s.elastic.co/v1beta1"
    kind       = "Beat"
    metadata = {
      name      = "${module.name.name}-filebeat"
      namespace = local.namespace
    }
    spec = {
      type    = "filebeat"
      version = lookup(local.filebeat_spec, "version", "8.15.0")
      image   = lookup(local.filebeat_spec, "image", null)
      elasticsearchRef = {
        name = lookup(local.filebeat_spec, "elasticsearchRef_name", "${module.name.name}-es")
      }
      kibanaRef = {
        name = lookup(local.filebeat_spec, "kibanaRef_name", "${module.name.name}-kibana")
      }
      config = lookup(local.filebeat_spec, "config", {
        "output.logstash" = {
          hosts = ["${module.name.name}-logstash-ls-beats.${local.namespace}.svc.cluster.local:5044"]
        }
        filebeat = {
          autodiscover = {
            providers = concat([
              {
                type = "kubernetes"
                node = "$${NODE_NAME}"
                hints = {
                  enabled = true
                  default_config = {
                    type  = "container"
                    paths = ["/var/log/containers/*$${data.kubernetes.container.id}.log"]
                  }
                }
              }
            ], lookup(local.filebeat_spec, "providers", []))
          }
        }
        processors = concat([
          {
            add_cloud_metadata = {}
          },
          {
            add_host_metadata = {}
          }
        ], lookup(local.filebeat_spec, "processors", []))
      })
      daemonSet = lookup(local.filebeat_spec, "daemonSet", {
        podTemplate = {
          spec = {
            serviceAccountName            = "${module.name.name}-filebeat"
            automountServiceAccountToken  = true
            terminationGracePeriodSeconds = 30
            dnsPolicy                     = "ClusterFirstWithHostNet"
            hostNetwork                   = true
            containers = [
              {
                name = "filebeat"
                resources = {
                  requests = {
                    memory = local.filebeat_spec.memory
                    cpu    = local.filebeat_spec.cpu
                  }
                  limits = {
                    memory = lookup(local.filebeat_spec, "memory_limit", local.filebeat_spec.memory)
                    cpu    = lookup(local.filebeat_spec, "cpu_limit", local.filebeat_spec.cpu)
                  }
                }
                securityContext = {
                  runAsUser = 0
                }
                volumeMounts = concat([
                  {
                    name      = "varlogcontainers"
                    mountPath = "/var/log/containers"
                  },
                  {
                    name      = "varlogpods"
                    mountPath = "/var/log/pods"
                  },
                  {
                    name      = "varlibdockercontainers"
                    mountPath = "/var/lib/docker/containers"
                  },
                  {
                    name      = "default-ilm-configmap-volume"
                    mountPath = "/usr/share/filebeat/ilm-policy.json"
                    subPath   = "ilm-policy.json"
                    readOnly  = true
                  }
                ], lookup(local.filebeat_spec, "volumeMounts", []))
                env = [
                  {
                    name = "NODE_NAME"
                    valueFrom = {
                      fieldRef = {
                        fieldPath = "spec.nodeName"
                      }
                    }
                  }
                ]
              }
            ]
            volumes = concat([
              {
                name = "varlogcontainers"
                hostPath = {
                  path = "/var/log/containers"
                }
              },
              {
                name = "varlogpods"
                hostPath = {
                  path = "/var/log/pods"
                }
              },
              {
                name = "varlibdockercontainers"
                hostPath = {
                  path = "/var/lib/docker/containers"
                }
              },
              {
                name = "default-ilm-configmap-volume"
                configMap = {
                  name = "${module.name.name}-default-ilmpolicy"
                }
              }
            ], lookup(local.filebeat_spec, "volumes", []))
            tolerations = local.tolerations
          }
        }
      })
    }
  }
  filebeat_sa = {
    apiVersion = "v1"
    kind       = "ServiceAccount"
    metadata = {
      name      = "${module.name.name}-filebeat"
      namespace = local.namespace
    }
  }
  filebeat_cr = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRole"
    metadata = {
      name = "${module.name.name}-filebeat"
    }
    rules = [
      {
        apiGroups = [""]
        resources = ["namespaces", "pods", "nodes"]
        verbs     = ["get", "watch", "list"]
      },
      {
        apiGroups = ["apps"]
        resources = ["replicasets"]
        verbs     = ["get", "list", "watch"]
      },
      {
        apiGroups = ["batch"]
        resources = ["jobs"]
        verbs     = ["get", "list", "watch"]
      }
    ]
  }
  filebeat_crb = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "${module.name.name}-filebeat"
    }
    subjects = [
      {
        kind      = "ServiceAccount"
        name      = "${module.name.name}-filebeat"
        namespace = local.namespace
      }
    ]
    roleRef = {
      kind     = "ClusterRole"
      name     = "${module.name.name}-filebeat"
      apiGroup = "rbac.authorization.k8s.io"
    }
  }
  filebeat = [local.filebeat_config, local.filebeat_cr, local.filebeat_crb, local.filebeat_sa]
  logstash = {
    apiVersion = "logstash.k8s.elastic.co/v1alpha1"
    kind       = "Logstash"
    metadata = {
      name      = "${module.name.name}-logstash"
      namespace = local.namespace
    }
    spec = {
      version = lookup(local.logstash_spec, "version", "8.15.0")
      image   = lookup(local.logstash_spec, "image", null)
      config  = lookup(local.logstash_spec, "config", {})
      elasticsearchRefs = concat([
        {
          clusterName = "${module.name.name}-eck"
          name        = "${module.name.name}-es"
        }
      ], lookup(local.logstash_spec, "elasticsearchRefs", []))
      monitoring = lookup(local.logstash_spec, "monitoring", {})
      count      = lookup(local.logstash_spec, "instance_count", 1)
      podTemplate = lookup(local.logstash_spec, "podTemplate", {
        spec = {
          containers = [
            {
              name = "logstash"
              resources = {
                requests = {
                  memory = local.logstash_spec.memory
                  cpu    = local.logstash_spec.cpu
                }
                limits = {
                  memory = lookup(local.logstash_spec, "memory_limit", local.logstash_spec.memory)
                  cpu    = lookup(local.logstash_spec, "cpu_limit", local.logstash_spec.cpu)
                }
              }
            }
          ]
          tolerations = local.tolerations
        }
      })
      pipelines = concat([
        {
          "pipeline.id"   = "main"
          "config.string" = <<-EOT
          input {
            beats {
              port => 5044
            }
          }
          filter {
            grok {
              match => { "message" => "%%{HTTPD_COMMONLOG}" }
            }
            geoip {
              source => "[source][address]"
              target => "[source]"
            }
          }
          output {
            elasticsearch {
              hosts => [ "$${${local.normalised_clustername}_ES_HOSTS}" ]
              user => "$${${local.normalised_clustername}_ES_USER}"
              password => "$${${local.normalised_clustername}_ES_PASSWORD}"
              ssl_certificate_authorities => "$${${local.normalised_clustername}_ES_SSL_CERTIFICATE_AUTHORITY}"
            }
          }
        EOT
        }
      ], lookup(local.logstash_spec, "pipelines", []))
      services = concat([
        {
          name = "beats"
          service = {
            spec = {
              type = "ClusterIP"
              ports = [
                {
                  port       = 5044
                  name       = "${module.name.name}-filebeat"
                  protocol   = "TCP"
                  targetPort = 5044
                }
              ]
            }
          }
        }
      ], lookup(local.logstash_spec, "services", []))
      revisionHistoryLimit = lookup(local.logstash_spec, "revisionHistoryLimit", 5)
    }
  }
  logstash_volume = lookup(local.logstash_spec, "volume", "10Gi")
}


