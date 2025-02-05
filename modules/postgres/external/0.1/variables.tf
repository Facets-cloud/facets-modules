variable "writer_details" {
  description = "Details for the PostgreSQL writer instance"
  type = object({
    host     = string
    username = string
    password = string
    port     = string
  })
}

variable "reader_details" {
  description = "Details for the PostgreSQL reader instance"
  type = object({
    host     = string
    username = string
    password = string
    port     = string
  })
}
