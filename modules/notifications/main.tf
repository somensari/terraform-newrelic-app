locals {
  prefix = "${var.environment}-${var.app_name}"

  pd_enabled    = try(var.notifications.pagerduty.enabled, false)
  slack_enabled = try(var.notifications.slack.enabled, false)
  email_enabled = try(var.notifications.email.enabled, false)
}

# ─── PagerDuty ────────────────────────────────────────────────────────────────

resource "newrelic_notification_destination" "pagerduty" {
  count = local.pd_enabled ? 1 : 0

  account_id = var.account_id
  name       = "${local.prefix}-pagerduty"
  type       = "PAGERDUTY_SERVICE_INTEGRATION"

  property {
    key   = "token"
    value = var.notifications.pagerduty.integration_key
  }
}

resource "newrelic_notification_channel" "pagerduty" {
  count = local.pd_enabled ? 1 : 0

  account_id     = var.account_id
  name           = "${local.prefix}-pagerduty"
  type           = "PAGERDUTY_SERVICE_INTEGRATION"
  destination_id = newrelic_notification_destination.pagerduty[0].id
  product        = "IINT"

  property {
    key   = "summary"
    value = "[${upper(var.environment)}] {{ issueTitle }}"
  }
}

# ─── Slack ────────────────────────────────────────────────────────────────────

resource "newrelic_notification_destination" "slack" {
  count = local.slack_enabled ? 1 : 0

  account_id = var.account_id
  name       = "${local.prefix}-slack"
  type       = "SLACK"

  property {
    key   = "url"
    value = var.notifications.slack.webhook
  }
}

resource "newrelic_notification_channel" "slack" {
  count = local.slack_enabled ? 1 : 0

  account_id     = var.account_id
  name           = "${local.prefix}-slack"
  type           = "SLACK"
  destination_id = newrelic_notification_destination.slack[0].id
  product        = "IINT"

  property {
    key   = "channelId"
    value = var.notifications.slack.channel_id
  }
  property {
    key   = "customDetailsSlack"
    value = "issue id - {{issueId}}"
  }
}

# ─── Email ────────────────────────────────────────────────────────────────────

resource "newrelic_notification_destination" "email" {
  count = local.email_enabled ? 1 : 0

  account_id = var.account_id
  name       = "${local.prefix}-email"
  type       = "EMAIL"

  property {
    key   = "email"
    value = join(",", var.notifications.email.addresses)
  }
}

resource "newrelic_notification_channel" "email" {
  count = local.email_enabled ? 1 : 0

  account_id     = var.account_id
  name           = "${local.prefix}-email"
  type           = "EMAIL"
  destination_id = newrelic_notification_destination.email[0].id
  product        = "IINT"

  property {
    key   = "subject"
    value = "[${upper(var.environment)}] {{ issueTitle }}"
  }
}

# ─── Workflow — wires all active channels to the alert policy ─────────────────

locals {
  active_channel_ids = compact([
    try(newrelic_notification_channel.pagerduty[0].id, null),
    try(newrelic_notification_channel.slack[0].id, null),
    try(newrelic_notification_channel.email[0].id, null),
  ])
}

resource "newrelic_workflow" "this" {
  count = length(local.active_channel_ids) > 0 ? 1 : 0

  account_id            = var.account_id
  name                  = "${local.prefix}-workflow"
  muting_rules_handling = "NOTIFY_ALL_ISSUES"
  enabled               = true

  issues_filter {
    name = "policy-filter"
    type = "FILTER"

    predicate {
      attribute = "labels.policyIds"
      operator  = "EXACTLY_MATCHES"
      values    = [tostring(var.policy_id)]
    }
  }

  dynamic "destination" {
    for_each = local.active_channel_ids
    content {
      channel_id            = destination.value
      notification_triggers = ["ACTIVATED", "ACKNOWLEDGED", "CLOSED"]
    }
  }
}
