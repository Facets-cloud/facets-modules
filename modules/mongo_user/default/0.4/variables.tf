variable "instance" {
  type = any
}


variable "instance_name" {
  type = string
}

variable "environment" {
  type = any
  default = {
    namespace = "default"
  }
}

variable "inputs" {
  type = object({
    mongo_details = object({
      interfaces = object({
        writer = object({
          connection_string = string
        })
      })
    })
  })
}
