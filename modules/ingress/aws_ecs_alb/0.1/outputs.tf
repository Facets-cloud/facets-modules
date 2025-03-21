locals {
  output_attributes = {
    # Define the attributes that should be output by the module
  }

  output_interfaces = merge(
    {
      for rule_key, rule in var.instance.spec.rules : "facets-${rule_key}" => {
        connection_string = "https://${lookup(rule, "domain_prefix", "") != "" ? "${lookup(rule, "domain_prefix", "")}." : ""}${local.unique_domain}"
        host              = "${lookup(rule, "domain_prefix", "") != "" ? "${lookup(rule, "domain_prefix", "")}." : ""}${local.unique_domain}"
        port              = 443
        username          = "na"
        password          = "na"
      }
    },
    [
      for domain_key, domain in lookup(var.instance.spec, "additional_domains", {}) : {
        for rule_key, rule in var.instance.spec.rules : "${domain_key}-${rule_key}" => {
          connection_string = "https://${lookup(rule, "domain_prefix", "") != "" ? "${lookup(rule, "domain_prefix", "")}." : ""}${domain.domain}"
          host              = "${lookup(rule, "domain_prefix", "") != "" ? "${lookup(rule, "domain_prefix", "")}." : ""}${domain.domain}"
          port              = 443
          username          = "na"
          password          = "na"
        }
      }
    ]...
  )
}
