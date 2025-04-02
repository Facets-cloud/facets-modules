locals {
  spec = lookup(var.instance, "spec", {})

  clients = [for client_name, client_config in lookup(local.spec, "clients", {}) : {
    allowed_oauth_flows                           = lookup(client_config, "allowed_oauth_flows", [])
    allowed_oauth_flows_user_pool_client          = lookup(client_config, "allowed_oauth_flows_user_pool_client", true)
    allowed_oauth_scopes                          = lookup(client_config, "allowed_oauth_scopes", [])
    auth_session_validity                         = lookup(client_config, "auth_session_validity", 3)
    callback_urls                                 = lookup(client_config, "callback_urls", [])
    default_redirect_uri                          = lookup(client_config, "default_redirect_uri", "")
    explicit_auth_flows                           = lookup(client_config, "explicit_auth_flows", [])
    generate_secret                               = lookup(client_config, "generate_secret", true)
    logout_urls                                   = lookup(client_config, "logout_urls", [])
    name                                          = client_name
    read_attributes                               = lookup(client_config, "read_attributes", [])
    access_token_validity                         = lookup(client_config, "access_token_validity", 60)
    id_token_validity                             = lookup(client_config, "id_token_validity", 60)
    refresh_token_validity                        = lookup(client_config, "refresh_token_validity", 30)
    enable_propagate_additional_user_context_data = lookup(client_config, "enable_propagate_additional_user_context_data", false)
    token_validity_units                          = lookup(client_config, "token_validity_units", { "access_token" : "minutes", "id_token" : "minutes", "refresh_token" : "days" })
    supported_identity_providers                  = lookup(client_config, "supported_identity_providers", [])
    prevent_user_existence_errors                 = lookup(client_config, "prevent_user_existence_errors", null)
    write_attributes                              = lookup(client_config, "write_attributes", [])
    enable_token_revocation                       = lookup(client_config, "enable_token_revocation", true)
  }]

  identity_providers = [for provider_name, provider_config in lookup(local.spec, "identity_providers", {}) : {
    provider_name     = provider_name
    provider_type     = lookup(provider_config, "provider_type", "")
    attribute_mapping = lookup(provider_config, "attribute_mapping", {})
    idp_identifiers   = lookup(provider_config, "idp_identifiers", [])
    provider_details  = lookup(provider_config, "provider_details", {})
  }]
}
