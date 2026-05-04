output "policy_id" {
  value = newrelic_alert_policy.this.id
}

output "policy_name" {
  value = newrelic_alert_policy.this.name
}

output "condition_ids" {
  value = { for k, v in newrelic_nrql_alert_condition.this : k => v.id }
}
