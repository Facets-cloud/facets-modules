locals {
  output_interfaces = {
    reader = {
      host              = var.instance.spec.reader_details.host
      username          = var.instance.spec.reader_details.username
      password          = sensitive(var.instance.spec.reader_details.password)
      port              = var.instance.spec.reader_details.port
      connection_string = sensitive("postgres://${var.instance.spec.reader_details.username}:${var.instance.spec.reader_details.password}@${var.instance.spec.reader_details.host}:${var.instance.spec.reader_details.port}")
      secrets           = ["password", "connection_string"]
      db_names          = []  # Assuming db_names are not provided
    }
    writer = {
      host              = var.instance.spec.writer_details.host
      username          = var.instance.spec.writer_details.username
      password          = sensitive(var.instance.spec.writer_details.password)
      port              = var.instance.spec.writer_details.port
      connection_string = sensitive("postgres://${var.instance.spec.writer_details.username}:${var.instance.spec.writer_details.password}@${var.instance.spec.writer_details.host}:${var.instance.spec.writer_details.port}")
      secrets           = ["password", "connection_string"]
      db_names          = []  # Assuming db_names are not provided
    }
  }

  output_attributes = {}  // Leaving attributes empty
}
