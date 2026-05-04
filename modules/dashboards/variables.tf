variable "account_id" {
  type = string
}

variable "app_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "active_dashboards" {
  description = "Pre-computed map of dashboards to create (from parent module locals)"
  type = map(object({
    name = string
  }))
}
