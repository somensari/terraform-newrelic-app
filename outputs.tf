output "policy_id" {
  description = "ID of the alert policy created for this app"
  value       = module.alerts.policy_id
}

output "policy_name" {
  description = "Name of the alert policy"
  value       = module.alerts.policy_name
}

output "active_alert_keys" {
  description = "Keys of the alert conditions that were created"
  value       = keys(local.active_alerts)
}

output "dashboard_ids" {
  description = "Map of dashboard key to dashboard ID"
  value       = module.dashboards.dashboard_ids
}

output "synthetic_monitor_ids" {
  description = "Map of synthetic key to monitor ID"
  value       = module.synthetics.monitor_ids
}
