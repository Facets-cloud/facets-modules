variable "cluster" {
  type = any
  default = {}
}

variable "cc_metadata" {
  type = any
}

variable "instance" {
  type = any
  default = {
    spec = {
      public = false
      rules = {}
    }
    metadata = {
      name = ""
      tags = {}
    }
  }
}

# Structure for reference:
# type = object({
#   spec = object({
#     public = bool
#     rules = map(object({
#       priority = number
#       action_type = string
#       forward_ecs = optional(object({
#         ecs_service_arn = string
#         port            = number
#         stickiness = optional(object({
#           enabled  = bool
#           duration = number
#         }))
#       }))
#       forward_target_group = optional(object({
#         target_group_arn = string
#         weight           = optional(number)
#         stickiness = optional(object({
#           enabled  = bool
#           duration = number
#         }))
#       }))
#       redirect = optional(object({
#         host        = optional(string)
#         path        = optional(string)
#         port        = optional(string)
#         protocol    = optional(string)
#         query       = optional(string)
#         status_code = string
#       }))
#       fixed_response = optional(object({
#         content_type = string
#         message_body = optional(string)
#         status_code  = optional(string)
#       }))
#       authenticate_cognito = optional(object({
#         user_pool_arn       = string
#         user_pool_client_id = string
#         user_pool_domain    = string
#         authentication_request_extra_params = optional(map(string))
#         on_unauthenticated_request = optional(string)
#         scope               = optional(string)
#         session_cookie_name = optional(string)
#         session_timeout     = optional(number)
#       }))
#       authenticate_oidc = optional(object({
#         authorization_endpoint = string
#         client_id              = string
#         client_secret          = string
#         issuer                 = string
#         token_endpoint         = string
#         user_info_endpoint     = string
#         authentication_request_extra_params = optional(map(string))
#         on_unauthenticated_request = optional(string)
#         scope               = optional(string)
#         session_cookie_name = optional(string)
#         session_timeout     = optional(number)
#       }))
#       condition = object({
#         domain_prefix = optional(string)
#         path_pattern = optional(object({
#           values = list(string)
#         }))
#         http_header = optional(object({
#           http_header_name = string
#           values           = list(string)
#         }))
#         http_request_method = optional(object({
#           values = list(string)
#         }))
#         query_string = optional(list(object({
#           key   = optional(string)
#           value = string
#         })))
#         source_ip = optional(object({
#           values = list(string)
#         }))
#       })
#     }))
#   })
#   metadata = object({
#     name = string
#     tags = map(string)
#   })
# })

variable "instance_name" {
  type    = string
  default = ""
}

variable "inputs" {
  type = any
}

variable "environment" {
  type    = any
  default = {}
}
