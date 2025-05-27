locals {
  output_interfaces = {}
  output_attributes = {
    kms_key_arn                       = module.kms.key_arn
    kms_key_id                        = module.kms.key_id
    kms_key_policy                    = module.kms.key_policy
    kms_external_key_expiration_model = module.kms.external_key_expiration_model
    kms_external_key_state            = module.kms.external_key_state
    kms_external_key_usage            = module.kms.external_key_usage
    kms_aliases                       = module.kms.aliases
    kms_grants                        = module.kms.grants
    secrets                           = ["kms_grants"]
  }
}
