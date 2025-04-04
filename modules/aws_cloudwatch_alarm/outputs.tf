locals {
  output_interfaces = {}
  output_attributes = {
    for alarm_key, alarm_value in local.alarms : alarm_key => {
      cloudwatch_metric_alarm_arn = module.metric_alarm[alarm_key].cloudwatch_metric_alarm_arn
      cloudwatch_metric_alarm_id  = module.metric_alarm[alarm_key].cloudwatch_metric_alarm_id
    }
  }
}
