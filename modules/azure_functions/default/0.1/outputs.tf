locals {

  function_application = {
  }
  output_attributes = {
    function_app_kind                  = local.os == "Linux" ? azurerm_linux_function_app.linux_function_app[0].kind : azurerm_windows_function_app.windows_function_app[0].kind
    function_app_name                  = local.os == "Linux" ? azurerm_linux_function_app.linux_function_app[0].name : azurerm_windows_function_app.windows_function_app[0].name
    function_app_slot_default_hostname = local.os == "Linux" ? azurerm_linux_function_app.linux_function_app[0].default_hostname : azurerm_windows_function_app.windows_function_app[0].default_hostname
    storage_account_id                 = azurerm_storage_account.az_func_storage_account.name
    site_name                          = local.os == "Linux" ? azurerm_linux_function_app.linux_function_app[0].site_credential[0].name : azurerm_windows_function_app.windows_function_app[0].site_credential[0].name
    site_password                      = local.os == "Linux" ? azurerm_linux_function_app.linux_function_app[0].site_credential[0].password : azurerm_windows_function_app.windows_function_app[0].site_credential[0].password
    secrets                            = ["site_password"]
  }
  output_interfaces = {}
}
output "functions_application" {
  value = local.output_attributes
}