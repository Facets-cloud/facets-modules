locals {
  output_interfaces = {
    reader = {
      host              = var.reader_details.host
      username          = var.reader_details.username
      password          = sensitive(var.reader_details.password)
      port              = var.reader_details.port
      connection_string = sensitive("postgres://${var.reader_details.username}:${var.reader_details.password}@${var.reader_details.host}:${var.reader_details.port}")
      secrets           = ["password", "connection_string"]
      db_names          = []  # Assuming db_names are not provided
    }
    writer = {
      host              = var.writer_details.host
      username          = var.writer_details.username
      password          = sensitive(var.writer_details.password)
      port              = var.writer_details.port
      connection_string = sensitive("postgres://${var.writer_details.username}:${var.writer_details.password}@${var.writer_details.host}:${var.writer_details.port}")
      secrets           = ["password", "connection_string"]
      db_names          = []  # Assuming db_names are not provided
    }
  }

  output_attributes = {}  // Leaving attributes empty
}
