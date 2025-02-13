locals {
  is_kubelet_scrape    = lookup(lookup(local.promtail_config, "scrape_kubelet_logs", {}), "enabled", false)
  scrape_extra_matches = lookup(lookup(local.promtail_config, "scrape_kubelet_logs", {}), "scrape_extra_matches", [])
  scrape_matches = concat([
    for scrape_extra_match in local.scrape_extra_matches : "_SYSTEMD_UNIT=${scrape_extra_match}"
    ], [
    "_SYSTEMD_UNIT=kubelet.service"
  ])

  # To schedule promtail(Daemonset) in all nodes (custom Nodepools as well)
  promtail_tolerations = [{
    operator = "Exists"
  }]

  default_promtail = {
    config = {
      clients = [
        {
          url = "http://${local.loki_endpoint}/loki/api/v1/push"
        }
      ]

      snippets = {
        pipelineStages = [
          {
            docker = {}
          },
          {
            labeldrop = [
              "filename",
              "container",
              "pod",
              "job"
            ]
          }
        ]
        extraScrapeConfigs = local.is_kubelet_scrape ? yamlencode(
          [
            {
              job_name = "journal"
              journal = {
                path    = "/var/log/journal"
                max_age = "12h"
                labels = {
                  job = "systemd-journal"
                }
                matches = join(" ", local.scrape_matches)
              }
              relabel_configs = [
                {
                  source_labels = [
                    "__journal__systemd_unit"
                  ],
                  target_label = "app"
                },
                {
                  source_labels = [
                    "__journal__hostname"
                  ],
                  target_label = "hostname"
                }
              ]
            }
          ]
        ) : ""
      }
    }

    podLabels = {
      resourceName = local.instance_name
      resourceType = "log_collector"
    }

    extraVolumes = local.is_kubelet_scrape ? [
      {
        name = "journal"
        hostPath = {
          path = "/var/log/journal"
        }
      }
    ] : []

    extraVolumeMounts = local.is_kubelet_scrape ? [
      {
        name      = "journal"
        mountPath = "/var/log/journal"
        readOnly  = true
      }
    ] : []

    nodeSelector = local.node_selectors
    tolerations  = local.promtail_tolerations

    serviceMonitor = {
      enabled = true
    }

    resources = {
      requests = {
        memory = "500Mi"
        cpu    = "200m"
      }
      limits = {
        memory = "1500Mi"
        cpu    = "1000m"
      }
    }

    priorityClassName = "facets-critical"
  }
}
