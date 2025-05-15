#######################################################################
# Terraform Module Structure                                          #
#                                                                     #
# ── Guidance for Code Generators / AI Tools ───────────────────────── #
#                                                                     #
# • Keep this main.tf file **intentionally empty**.                   #
#   It serves only as the module's entry point.                       #
#                                                                     #
# • Create additional *.tf files that are **logically grouped**        #
#   according to the functionality and resources of the module.       #
#                                                                     #
# • Group related resources, data sources, locals, variables, and     #
#   outputs into separate files to improve clarity and maintainability.#
#                                                                     #
# • Choose file names that clearly reflect the purpose of the contents.#
#                                                                     #
# • Add new files as needed when new functionality areas are introduced,#
#   instead of expanding existing files indefinitely.                 #
#                                                                     #
# This ensures modules stay clean, scalable, and easy to navigate.    #
#######################################################################