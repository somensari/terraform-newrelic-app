output "workflow_id" {
  value = try(newrelic_workflow.this[0].id, null)
}

output "channel_ids" {
  value = local.active_channel_ids
}
