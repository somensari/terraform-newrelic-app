resource "newrelic_alert_policy" "this" {
  account_id          = var.account_id
  name                = "${var.environment}-${var.app_name}"
  incident_preference = "PER_CONDITION"
}

resource "newrelic_nrql_alert_condition" "this" {
  for_each = var.active_alerts

  account_id = var.account_id
  policy_id  = newrelic_alert_policy.this.id
  name       = each.value.name
  type       = "static"
  enabled    = true

  aggregation_method = "event_flow"
  aggregation_delay  = 120
  aggregation_window = 60

  expiration_duration            = 600
  open_violation_on_expiration   = false
  close_violations_on_expiration = false

  violation_time_limit_seconds = 86400

  nrql {
    query = each.value.nrql
  }

  critical {
    operator              = each.value.operator
    threshold             = each.value.critical
    threshold_duration    = each.value.critical_duration
    threshold_occurrences = "ALL"
  }

  dynamic "warning" {
    for_each = each.value.warning != null ? [1] : []
    content {
      operator              = each.value.operator
      threshold             = each.value.warning
      threshold_duration    = each.value.warning_duration
      threshold_occurrences = "ALL"
    }
  }
}
