variable "account_id" {
  type = string
}

variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "active_alerts" {
  description = "Pre-computed map of alerts to create (from parent module locals)"
  type = map(object({
    name              = string
    nrql              = string
    operator          = string
    critical          = number
    critical_duration = number
    warning           = optional(number)
    warning_duration  = optional(number)
  }))
}

variable "labels" {
  description = "Labels to apply to all alert conditions"
  type        = map(string)
  default     = {}
}
