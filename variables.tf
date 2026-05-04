variable "account_id" {
  type        = string
  description = "New Relic account ID"
}

variable "app_name" {
  type        = string
  description = "Application name as it appears in New Relic (must match exactly)"
}

variable "environment" {
  type        = string
  description = "Deployment environment: prod, staging, or dev"
  validation {
    condition     = contains(["prod", "staging", "dev"], var.environment)
    error_message = "environment must be one of: prod, staging, dev"
  }
}

# ─── Alerts ───────────────────────────────────────────────────────────────────

variable "alerts" {
  description = <<-EOT
    Catalog alerts to enable. Keys must match entries in the catalog (see locals.tf).
    Only the keys you include will be created. Override any field or leave empty to use catalog defaults.

    Example:
      alerts = {
        error_rate    = {}                    # all defaults
        response_time = { critical = 1.5 }   # override critical threshold only
        apdex         = { enabled = false }   # explicitly skip
      }
  EOT
  type = map(object({
    name              = optional(string)
    nrql              = optional(string)
    operator          = optional(string)
    critical          = optional(number)
    critical_duration = optional(number)
    warning           = optional(number)
    warning_duration  = optional(number)
    enabled           = optional(bool, true)
  }))
  default = {}
}

variable "custom_alerts" {
  description = <<-EOT
    Additional alerts not in the catalog. All required fields must be provided.

    Example:
      custom_alerts = {
        payment_failures = {
          name     = "Payment Failures"
          nrql     = "SELECT count(*) FROM PaymentEvent WHERE status = 'failed'"
          operator = "above"
          critical = 50
          warning  = 20
        }
      }
  EOT
  type = map(object({
    name              = string
    nrql              = string
    operator          = optional(string, "above")
    critical          = number
    critical_duration = optional(number, 300)
    warning           = optional(number)
    warning_duration  = optional(number, 300)
    enabled           = optional(bool, true)
  }))
  default = {}
}

# ─── Dashboards ───────────────────────────────────────────────────────────────

variable "dashboards" {
  description = <<-EOT
    Catalog dashboards to enable. Keys must match entries in the catalog.

    Example:
      dashboards = {
        apm_overview   = {}
        infrastructure = { name = "My Custom Name" }
      }
  EOT
  type = map(object({
    name    = optional(string)
    enabled = optional(bool, true)
  }))
  default = {}
}

# ─── Synthetics ───────────────────────────────────────────────────────────────

variable "synthetics" {
  description = <<-EOT
    Catalog synthetic monitors to enable. Keys: ping, browser, api.
    uri is required for ping and browser types.

    Example:
      synthetics = {
        ping    = { uri = "https://myapp.com/health" }
        browser = { uri = "https://myapp.com" }
      }
  EOT
  type = map(object({
    name    = optional(string)
    uri     = optional(string)
    period  = optional(string)
    enabled = optional(bool, true)
  }))
  default = {}
}

# ─── Notifications ────────────────────────────────────────────────────────────

variable "notifications" {
  description = <<-EOT
    Notification destinations to wire to the alert policy workflow.
    Only enabled destinations will be created.

    Example:
      notifications = {
        pagerduty = { enabled = true, integration_key = var.pd_key }
        slack     = { enabled = true, webhook = var.slack_webhook, channel_id = "C0123456" }
        email     = { enabled = true, addresses = ["oncall@example.com"] }
      }
  EOT
  type = object({
    pagerduty = optional(object({
      enabled         = optional(bool, false)
      integration_key = optional(string, "")
    }), {})
    slack = optional(object({
      enabled    = optional(bool, false)
      webhook    = optional(string, "")
      channel_id = optional(string, "")
    }), {})
    email = optional(object({
      enabled   = optional(bool, false)
      addresses = optional(list(string), [])
    }), {})
  })
  default = {}
}
