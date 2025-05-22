locals {
  helm_values = jsondecode(helm_release.rabbitmq.metadata[0].values)
  output_interfaces = {
    cluster = {
      endpoint          = var.instance.spec.cluster.endpoint
      connection_string = sensitive("amqp://${var.instance.spec.cluster.username}:${var.instance.spec.cluster.password}@${var.instance.spec.cluster.endpoint}:${var.instance.spec.cluster.port}")
      username          = var.instance.spec.cluster.username
      password          = sensitive(var.instance.spec.cluster.password)
      port              = var.instance.spec.cluster.port
      secrets           = ["password", "connection_string"]
    }
    tcp = {
      endpoint          = var.instance.spec.tcp.endpoint
      connection_string = sensitive("amqp://${var.instance.spec.tcp.username}:${var.instance.spec.tcp.password}@${var.instance.spec.tcp.endpoint}:${var.instance.spec.tcp.port}")
      username          = var.instance.spec.tcp.username
      password          = sensitive(var.instance.spec.tcp.password)
      port              = var.instance.spec.tcp.port
      secrets           = ["password", "connection_string"]
    }
    http = {
      endpoint          = var.instance.spec.http.endpoint
      connection_string = sensitive("amqp://${var.instance.spec.http.username}:${var.instance.spec.http.password}@${var.instance.spec.http.endpoint}:${var.instance.spec.http.port}")
      username          = var.instance.spec.http.username
      password          = sensitive(var.instance.spec.http.password)
      port              = var.instance.spec.http.port
      secrets           = ["password", "connection_string"]
    }
  }

  output_attributes = {}
}