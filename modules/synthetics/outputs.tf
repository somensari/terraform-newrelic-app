output "monitor_ids" {
  value = { for k, v in newrelic_synthetics_monitor.this : k => v.id }
}
