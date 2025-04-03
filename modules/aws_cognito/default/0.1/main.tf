module "name" {
  count = length(lookup(local.spec, "user_pool_name", {})) > 0 ? 0 : 1

  source          = "github.com/Facets-cloud/facets-utility-modules//name"
  environment     = var.environment
  limit           = 128
  resource_name   = var.instance_name
  resource_type   = "ws_cognito"
  globally_unique = true
  is_k8s          = false
  prefix          = "a"
}


module "aws-cognito" {
  source = "./terraform-aws-cognito-user-pool-0.33.0"

  # Required
  user_pool_name = lookup(local.spec, "user_pool_name", module.name[0].name)

  # Optional
  admin_create_user_config                                   = lookup(local.spec, "admin_create_user_config", {})
  admin_create_user_config_allow_admin_create_user_only      = lookup(local.spec, "admin_create_user_config_allow_admin_create_user_only", true)
  admin_create_user_config_email_message                     = lookup(local.spec, "admin_create_user_config_email_message", "{username}, your verification code is `{####}`")
  admin_create_user_config_email_subject                     = lookup(local.spec, "admin_create_user_config_email_subject", "Your verification code")
  admin_create_user_config_sms_message                       = lookup(local.spec, "admin_create_user_config_sms_message", "Your username is {username} and temporary password is `{####}`")
  alias_attributes                                           = lookup(local.spec, "alias_attributes", null)
  auto_verified_attributes                                   = lookup(local.spec, "auto_verified_attributes", [])
  client_access_token_validity                               = lookup(local.spec, "client_access_token_validity", 60)
  client_allowed_oauth_flows                                 = lookup(local.spec, "client_allowed_oauth_flows", [])
  client_allowed_oauth_flows_user_pool_client                = lookup(local.spec, "client_allowed_oauth_flows_user_pool_client", true)
  client_allowed_oauth_scopes                                = lookup(local.spec, "client_allowed_oauth_scopes", [])
  client_auth_session_validity                               = lookup(local.spec, "client_auth_session_validity", 3)
  client_callback_urls                                       = lookup(local.spec, "client_callback_urls", [])
  client_default_redirect_uri                                = lookup(local.spec, "client_default_redirect_uri", "")
  client_enable_token_revocation                             = lookup(local.spec, "client_enable_token_revocation", true)
  client_explicit_auth_flows                                 = lookup(local.spec, "client_explicit_auth_flows", [])
  client_generate_secret                                     = lookup(local.spec, "client_generate_secret", true)
  client_id_token_validity                                   = lookup(local.spec, "client_id_token_validity", 60)
  client_logout_urls                                         = lookup(local.spec, "client_logout_urls", [])
  client_name                                                = lookup(local.spec, "client_name", null)
  client_prevent_user_existence_errors                       = lookup(local.spec, "client_prevent_user_existence_errors", null)
  client_read_attributes                                     = lookup(local.spec, "client_read_attributes", [])
  client_refresh_token_validity                              = lookup(local.spec, "client_refresh_token_validity", 30)
  client_supported_identity_providers                        = lookup(local.spec, "client_supported_identity_providers", [])
  client_token_validity_units                                = lookup(local.spec, "client_token_validity_units", { "access_token" : "minutes", "id_token" : "minutes", "refresh_token" : "days" })
  client_write_attributes                                    = lookup(local.spec, "client_write_attributes", [])
  clients                                                    = lookup(local.spec, "clients", [])
  default_ui_customization_css                               = lookup(local.spec, "default_ui_customization_css", null)
  default_ui_customization_image_file                        = lookup(local.spec, "default_ui_customization_image_file", null)
  deletion_protection                                        = lookup(local.spec, "deletion_protection", "INACTIVE")
  device_configuration                                       = lookup(local.spec, "device_configuration", {})
  device_configuration_challenge_required_on_new_device      = lookup(local.spec, "device_configuration_challenge_required_on_new_device", null)
  device_configuration_device_only_remembered_on_user_prompt = lookup(local.spec, "device_configuration_device_only_remembered_on_user_prompt", null)
  domain                                                     = lookup(local.spec, "domain", null)
  domain_certificate_arn                                     = lookup(local.spec, "domain_certificate_arn", null)
  email_configuration                                        = lookup(local.spec, "email_configuration", {})
  email_configuration_configuration_set                      = lookup(local.spec, "email_configuration_configuration_set", null)
  email_configuration_email_sending_account                  = lookup(local.spec, "email_configuration_email_sending_account", "COGNITO_DEFAULT")
  email_configuration_from_email_address                     = lookup(local.spec, "email_configuration_from_email_address", null)
  email_configuration_reply_to_email_address                 = lookup(local.spec, "email_configuration_reply_to_email_address", "")
  email_configuration_source_arn                             = lookup(local.spec, "email_configuration_source_arn", "")
  email_verification_message                                 = lookup(local.spec, "email_verification_message", null)
  email_verification_subject                                 = lookup(local.spec, "email_verification_subject", null)
  enable_propagate_additional_user_context_data              = lookup(local.spec, "enable_propagate_additional_user_context_data", false)
  enabled                                                    = lookup(local.spec, "enabled", true)
  identity_providers                                         = lookup(local.spec, "identity_providers", [])
  lambda_config                                              = lookup(local.spec, "lambda_config", {})
  lambda_config_create_auth_challenge                        = lookup(local.spec, "lambda_config_create_auth_challenge", null)
  lambda_config_custom_email_sender                          = lookup(local.spec, "lambda_config_custom_email_sender", {})
  lambda_config_custom_message                               = lookup(local.spec, "lambda_config_custom_message", null)
  lambda_config_custom_sms_sender                            = lookup(local.spec, "lambda_config_custom_sms_sender", {})
  lambda_config_define_auth_challenge                        = lookup(local.spec, "lambda_config_define_auth_challenge", null)
  lambda_config_kms_key_id                                   = lookup(local.spec, "lambda_config_kms_key_id", null)
  lambda_config_post_authentication                          = lookup(local.spec, "lambda_config_post_authentication", null)
  lambda_config_post_confirmation                            = lookup(local.spec, "lambda_config_post_confirmation", null)
  lambda_config_pre_authentication                           = lookup(local.spec, "lambda_config_pre_authentication", null)
  lambda_config_pre_sign_up                                  = lookup(local.spec, "lambda_config_pre_sign_up", null)
  lambda_config_pre_token_generation                         = lookup(local.spec, "lambda_config_pre_token_generation", null)
  lambda_config_pre_token_generation_config                  = lookup(local.spec, "lambda_config_pre_token_generation_config", {})
  lambda_config_user_migration                               = lookup(local.spec, "lambda_config_user_migration", null)
  lambda_config_verify_auth_challenge_response               = lookup(local.spec, "lambda_config_verify_auth_challenge_response", null)
  mfa_configuration                                          = lookup(local.spec, "mfa_configuration", "OFF")
  number_schemas                                             = lookup(local.spec, "number_schemas", [])
  password_policy                                            = lookup(local.spec, "password_policy", null)
  password_policy_minimum_length                             = lookup(local.spec, "password_policy_minimum_length", 8)
  password_policy_require_lowercase                          = lookup(local.spec, "password_policy_require_lowercase", true)
  password_policy_require_numbers                            = lookup(local.spec, "password_policy_require_numbers", true)
  password_policy_require_symbols                            = lookup(local.spec, "password_policy_require_symbols", true)
  password_policy_require_uppercase                          = lookup(local.spec, "password_policy_require_uppercase", true)
  password_policy_temporary_password_validity_days           = lookup(local.spec, "password_policy_temporary_password_validity_days", 7)
  recovery_mechanisms                                        = lookup(local.spec, "recovery_mechanisms", [])
  resource_server_identifier                                 = lookup(local.spec, "resource_server_identifier", null)
  resource_server_name                                       = lookup(local.spec, "resource_server_name", null)
  resource_server_scope_description                          = lookup(local.spec, "resource_server_scope_description", null)
  resource_server_scope_name                                 = lookup(local.spec, "resource_server_scope_name", null)
  resource_servers                                           = lookup(local.spec, "resource_servers", [])
  schemas                                                    = lookup(local.spec, "schemas", [])
  sms_authentication_message                                 = lookup(local.spec, "sms_authentication_message", null)
  sms_configuration                                          = lookup(local.spec, "sms_configuration", {})
  sms_configuration_external_id                              = lookup(local.spec, "sms_configuration_external_id", "")
  sms_configuration_sns_caller_arn                           = lookup(local.spec, "sms_configuration_sns_caller_arn", "")
  sms_verification_message                                   = lookup(local.spec, "sms_verification_message", null)
  software_token_mfa_configuration                           = lookup(local.spec, "software_token_mfa_configuration", {})
  software_token_mfa_configuration_enabled                   = lookup(local.spec, "software_token_mfa_configuration_enabled", false)
  string_schemas                                             = lookup(local.spec, "string_schemas", [])
  tags                                                       = merge(lookup(local.spec, "tags", {}), var.environment.cloud_tags)
  temporary_password_validity_days                           = lookup(local.spec, "temporary_password_validity_days", 7)
  user_attribute_update_settings                             = lookup(local.spec, "user_attribute_update_settings", null)
  user_group_description                                     = lookup(local.spec, "user_group_description", null)
  user_group_name                                            = lookup(local.spec, "user_group_name", null)
  user_group_precedence                                      = lookup(local.spec, "user_group_precedence", null)
  user_group_role_arn                                        = lookup(local.spec, "user_group_role_arn", null)
  user_groups                                                = lookup(local.spec, "user_groups", [])
  user_pool_add_ons                                          = lookup(local.spec, "user_pool_add_ons", {})
  user_pool_add_ons_advanced_security_mode                   = lookup(local.spec, "user_pool_add_ons_advanced_security_mode", null)
  username_attributes                                        = lookup(local.spec, "username_attributes", null)
  username_configuration                                     = lookup(local.spec, "username_configuration", {})
  verification_message_template                              = lookup(local.spec, "verification_message_template", {})
  verification_message_template_default_email_option         = lookup(local.spec, "verification_message_template_default_email_option", null)
  verification_message_template_email_message_by_link        = lookup(local.spec, "verification_message_template_email_message_by_link", null)
  verification_message_template_email_subject_by_link        = lookup(local.spec, "verification_message_template_email_subject_by_link", null)
}
