# Define your outputs here
locals {
  output_interfaces = {}
  output_attributes = {
    arn                 = module.api_gateway.apigatewayv2_api_arn
    endpoint            = module.api_gateway.apigatewayv2_api_api_endpoint
    execution_arn       = module.api_gateway.apigatewayv2_api_execution_arn
    id                  = module.api_gateway.apigatewayv2_api_id
    vpc_links_id        = module.api_gateway.apigatewayv2_vpc_link_id
    stage_arn           = module.api_gateway.default_apigatewayv2_stage_arn
    stage_execution_arn = module.api_gateway.default_apigatewayv2_stage_execution_arn
    stage_id            = module.api_gateway.default_apigatewayv2_stage_id
    stage_invoke_url    = module.api_gateway.default_apigatewayv2_stage_invoke_url
  }
}
