variable "account_id" {
  type = string
}

variable "active_synthetics" {
  description = "Pre-computed map of synthetic monitors to create (from parent module locals)"
  type = map(object({
    name   = string
    type   = string
    period = string
    uri    = optional(string)
  }))
}

variable "labels" {
  description = "Labels to apply to all synthetic monitors"
  type        = map(string)
  default     = {}
}
