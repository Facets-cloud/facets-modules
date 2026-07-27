#########################################################################
# Terraform Module Structure                                            #
#                                                                       #
# ── Guidance for Code Generators / AI Tools ──────────────────────────  #
#                                                                       #
# • This main.tf file serves as the module's entry point and overview.  #
#                                                                       #
# • All logic has been organized into separate files for maintainability:#
#   - locals.tf: Local values and calculations                          #
#   - network.tf: Core network infrastructure (RG, VNet)               #
#   - subnets.tf: All subnet resources                                 #
#   - nat-gateway.tf: NAT Gateway and associations                      #
#   - routing.tf: Route tables and routing configuration               #
#   - security-groups.tf: Network Security Groups                      #
#   - private-endpoints.tf: Private DNS zones and endpoints            #
#                                                                       #
# • This structure improves readability, maintainability, and          #
#   makes it easier for teams to work on specific components.          #
#                                                                       #
#########################################################################

# This Azure VPC module creates a comprehensive virtual network infrastructure
# with support for multiple subnet types, NAT gateways, private endpoints,
# and flexible CIDR allocation strategies.
#
# Key Features:
# - Dynamic or fixed CIDR allocation
# - Multiple subnet types (public, private, database, specialized)
# - NAT Gateway with per-AZ or shared strategies
# - Private endpoints with DNS integration
# - Comprehensive routing and security group configuration
#
# All resources are defined in their respective files for better organization.
