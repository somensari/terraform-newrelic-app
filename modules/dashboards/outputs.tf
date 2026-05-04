output "dashboard_ids" {
  value = { for k, v in newrelic_one_dashboard.this : k => v.id }
}
