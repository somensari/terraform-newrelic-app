variable "account_id" {
  type = string
}

variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "policy_id" {
  type        = string
  description = "Alert policy ID to attach this workflow to"
}

variable "notifications" {
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
