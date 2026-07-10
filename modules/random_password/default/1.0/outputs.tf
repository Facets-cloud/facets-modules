# ╔═══════════════════════════════════════════════════════════╗
# ║ Output contract: @facets/random_password                  ║
# ║ Keys managed by CLI — fill in the values only           ║
# ║ Do not add or remove keys. Do not rename.                 ║
# ║                                                           ║
# ║ View schema: raptor get output-type @facets/random_passwo ║
# ╚═══════════════════════════════════════════════════════════╝

locals {
  output_attributes = {
    result = random_password.this.result
  }
  output_interfaces = {
  }
}

# --- END MANAGED SECTION --- Add your custom outputs below ---

# Add your custom Terraform outputs below this line.
