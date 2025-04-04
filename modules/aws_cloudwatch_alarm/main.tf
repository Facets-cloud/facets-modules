module "metric_alarm" {
  for_each = local.alarms
  source   = "./metric-alarm"

  create_metric_alarm                   = lookup(each.value, "create_metric_alarm", true)
  alarm_name                            = lookup(each.value, "alarm_name", each.key)
  alarm_description                     = lookup(each.value, "alarm_description", null)
  actions_enabled                       = lookup(each.value, "actions_enabled", true)
  alarm_actions                         = lookup(each.value, "alarm_actions", null)
  ok_actions                            = lookup(each.value, "ok_actions", null)
  insufficient_data_actions             = lookup(each.value, "insufficient_data_actions", null)
  comparison_operator                   = lookup(each.value, "comparison_operator", null)
  evaluation_periods                    = lookup(each.value, "evaluation_periods", null)
  threshold                             = lookup(each.value, "threshold", null)
  threshold_metric_id                   = lookup(each.value, "threshold_metric_id", null)
  unit                                  = lookup(each.value, "unit", null)
  metric_name                           = lookup(each.value, "metric_name", null)
  namespace                             = lookup(each.value, "namespace", null)
  period                                = lookup(each.value, "period", null)
  statistic                             = lookup(each.value, "statistic", null)
  extended_statistic                    = lookup(each.value, "extended_statistic", null)
  datapoints_to_alarm                   = lookup(each.value, "datapoints_to_alarm", null)
  dimensions                            = lookup(each.value, "dimensions", null)
  treat_missing_data                    = lookup(each.value, "treat_missing_data", "missing")
  evaluate_low_sample_count_percentiles = lookup(each.value, "evaluate_low_sample_count_percentiles", null)
  metric_query                          = lookup(each.value, "metric_query", [])
  tags                                  = merge(lookup(each.value, "tags", {}), var.environment.cloud_tags)
}
