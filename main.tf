terraform {
  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = "~> 3.80"
    }
  }
}

module "alerts" {
  source = "./modules/alerts"

  account_id    = var.account_id
  app_name      = var.app_name
  environment   = var.environment
  active_alerts = local.active_alerts
  labels        = local.base_labels
}

module "dashboards" {
  source = "./modules/dashboards"

  account_id        = var.account_id
  app_name          = var.app_name
  environment       = var.environment
  active_dashboards = local.active_dashboards
  labels            = local.base_labels
}

module "synthetics" {
  source = "./modules/synthetics"

  account_id        = var.account_id
  active_synthetics = local.active_synthetics
  labels            = local.base_labels
}

module "notifications" {
  source = "./modules/notifications"

  account_id    = var.account_id
  app_name      = var.app_name
  environment   = var.environment
  policy_id     = module.alerts.policy_id
  notifications = var.notifications
}
