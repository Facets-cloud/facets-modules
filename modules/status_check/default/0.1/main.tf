# Define your terraform resources here

module "uptime_http_checks" {
  for_each        = lookup(local.processed_names, "http", {})
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = lower("${each.key}")
  namespace       = local.namespace
  advanced_config = lookup(local.advanced_config, "values", {})
  data = {

    apiVersion = "uptime.facets.cloud/v1alpha1"
    kind       = "HttpCheck"
    metadata = {
      name      = lower("${each.key}")
      namespace = local.namespace
      labels = merge(lookup(local.metadata, "labels", {}), {
        resourceType = "status_check"
      })
      annotations = lookup(local.metadata, "annotations", {})
    }
    spec = {
      runInterval        = lookup(local.advanced_config, "run_interval", "5m")
      timeout            = lookup(local.advanced_config, "timeout", "10m")
      count              = lookup(each.value, "count", "10")
      seconds            = lookup(each.value, "seconds", "1")
      passingPercent     = lookup(each.value, "passing_percent", "100")
      requestBody        = lookup(each.value, "body", "100")
      expectedResponse   = lookup(each.value, "expected_response", null)
      url                = lookup(each.value, "url", "")
      expectedStatusCode = lookup(each.value, "expected_status_code", "200-299")
      requestType        = upper(lookup(each.value, "method", "GET"))
    }
  }
}

module "uptime_mongo_checks" {
  for_each        = lookup(local.processed_names, "mongo", {})
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = lower("${each.key}")
  namespace       = local.namespace
  advanced_config = lookup(local.advanced_config, "values", {})
  data = {

    apiVersion = "uptime.facets.cloud/v1alpha1"
    kind       = "MongoCheck"
    metadata = {
      name      = lower("${each.key}")
      namespace = local.namespace
      labels = merge(lookup(local.metadata, "labels", {}), {
        resourceType = "status_check"
      })
      annotations = lookup(local.metadata, "annotations", {})
    }
    spec = {
      runInterval = lookup(local.advanced_config, "run_interval", "5m")
      timeout     = lookup(local.advanced_config, "timeout", "10m")
      url         = lookup(each.value, "url", "")
    }
  }
}

module "uptime_redis_checks" {
  for_each        = lookup(local.processed_names, "redis", {})
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = lower("${each.key}")
  namespace       = local.namespace
  advanced_config = lookup(local.advanced_config, "values", {})
  data = {

    apiVersion = "uptime.facets.cloud/v1alpha1"
    kind       = "RedisCheck"
    metadata = {
      name      = lower("${each.key}")
      namespace = local.namespace
      labels = merge(lookup(local.metadata, "labels", {}), {
        resourceType = "status_check"
      })
      annotations = lookup(local.metadata, "annotations", {})
    }
    spec = {
      runInterval = lookup(local.advanced_config, "run_interval", "5m")
      timeout     = lookup(local.advanced_config, "timeout", "10m")
      url         = lookup(each.value, "url", "")
    }
  }
}

module "uptime_tcp_checks" {
  for_each        = lookup(local.processed_names, "tcp", {})
  source          = "github.com/Facets-cloud/facets-utility-modules//any-k8s-resource"
  name            = lower("${each.key}")
  namespace       = local.namespace
  advanced_config = lookup(local.advanced_config, "values", {})
  data = {

    apiVersion = "uptime.facets.cloud/v1alpha1"
    kind       = "TcpCheck"
    metadata = {
      name      = lower("${each.key}")
      namespace = local.namespace
      labels = merge(lookup(local.metadata, "labels", {}), {
        resourceType = "status_check"
      })
      annotations = lookup(local.metadata, "annotations", {})
    }
    spec = {
      runInterval = lookup(local.advanced_config, "run_interval", "5m")
      timeout     = lookup(local.advanced_config, "timeout", "10m")
      url         = lookup(each.value, "url", "")
    }
  }
}


