# terraform-newrelic-app

Reusable Terraform module for New Relic observability. Creates alerts, dashboards, synthetic monitors, and notification routing for an application in a single call.

Teams opt in to only what they need — omitting a key means that resource is not created.

## Requirements

| Name | Version |
|------|---------|
| Terraform | `~> 1.5` |
| newrelic/newrelic | `~> 3.80` |

## Usage

```hcl
terraform {
  required_providers {
    newrelic = {
      source  = "newrelic/newrelic"
      version = "~> 3.80"
    }
  }
}

provider "newrelic" {
  account_id = var.account_id
  api_key    = var.api_key
  region     = "US"
}

module "my_app" {
  source = "git::https://github.com/somensari/terraform-newrelic-app.git?ref=v0.1.0"

  account_id  = var.account_id
  app_name    = "my-app"        # must match the name in New Relic exactly
  environment = "prod"          # prod | staging | dev

  alerts = {
    error_rate    = {}
    response_time = {}
    apdex         = {}
    host_cpu      = {}
  }

  dashboards = {
    apm_overview = {}
  }

  synthetics = {
    ping = { uri = "https://my-app.example.com/health" }
  }

  notifications = {
    pagerduty = {
      enabled         = true
      integration_key = var.pagerduty_key
    }
    slack = {
      enabled    = true
      webhook    = var.slack_webhook
      channel_id = var.slack_channel_id
    }
  }
}
```

## Environment scaling

Alert thresholds loosen automatically in non-prod environments so lower environments don't generate noise:

| Environment | Threshold multiplier |
|-------------|----------------------|
| `prod`      | 1× (baseline)        |
| `staging`   | 2×                   |
| `dev`       | 5×                   |

For example, `error_rate` has a critical threshold of 5% in prod, 10% in staging, and 25% in dev.

## Alert catalog

Enable an alert by including its key in the `alerts` variable. Pass `{}` to use catalog defaults, or override any field.

```hcl
alerts = {
  error_rate    = {}                                    # all defaults
  response_time = { critical = 1.5, warning = 0.8 }    # override thresholds
  apdex         = { enabled = false }                   # explicitly skip
}
```

### APM

| Key | What it detects | Critical (prod) | Warning (prod) |
|-----|----------------|-----------------|----------------|
| `error_rate` | Transaction error % | 5% | 2% |
| `response_time` | Avg transaction duration | 3s | 1s |
| `apdex` | Apdex score | below 0.70 | below 0.85 |
| `throughput` | Requests per minute | below 1 rpm | — |
| `golden_error_rate` | Error rate via golden metrics | 5% | 2% |
| `golden_response_time` | Response time via golden metrics | 3000ms | 1000ms |
| `golden_throughput` | Throughput via golden metrics | below 1 rpm | — |

### Infrastructure

| Key | What it detects | Critical | Warning |
|-----|----------------|----------|---------|
| `host_cpu` | Host CPU % | 90% | 75% |
| `host_memory` | Host memory % | 90% | 80% |
| `host_disk` | Disk usage % | 90% | 80% |

### Kubernetes

| Key | What it detects | Critical | Warning |
|-----|----------------|----------|---------|
| `k8s_pod_not_ready` | Pods not ready | any | — |
| `k8s_container_cpu` | Container CPU vs limit | 85% | 70% |
| `k8s_container_memory` | Container memory vs limit | 90% | 80% |
| `k8s_replicaset` | Missing pods in ReplicaSet | any | — |

### AWS

| Key | What it detects | Critical (prod) | Warning (prod) |
|-----|----------------|-----------------|----------------|
| `aws_alb_5xx` | ALB 5xx error count | 10 | 5 |
| `aws_alb_response_time` | ALB target response time | 3s | 1s |
| `aws_rds_cpu` | RDS CPU % | 90% | 75% |
| `aws_rds_connections` | RDS connection count | 500 | 400 |
| `aws_sqs_depth` | SQS visible message count | 1000 | 500 |
| `aws_lambda_errors` | Lambda error rate % | 5% | 2% |
| `aws_lambda_duration` | Lambda avg duration | 10000ms | 5000ms |

### Azure

| Key | What it detects | Critical (prod) | Warning (prod) |
|-----|----------------|-----------------|----------------|
| `azure_app_gateway_5xx` | App Gateway failed requests | 10 | 5 |
| `azure_sql_cpu` | Azure SQL CPU % | 90% | 75% |
| `azure_sql_dtu` | Azure SQL DTU % | 90% | 75% |
| `azure_servicebus_depth` | Service Bus active messages | 1000 | 500 |
| `azure_functions_5xx` | Azure Functions 5xx count | 10 | 5 |

### GCP

| Key | What it detects | Critical (prod) | Warning (prod) |
|-----|----------------|-----------------|----------------|
| `gcp_lb_5xx` | GCP LB 5xx request count | 10 | 5 |
| `gcp_cloudsql_cpu` | Cloud SQL CPU % | 90% | 75% |
| `gcp_pubsub_depth` | Pub/Sub undelivered messages | 1000 | 500 |
| `gcp_functions_errors` | Cloud Functions error count | 10 | 5 |
| `gcp_gke_node_cpu` | GKE node CPU allocatable % | 90% | 75% |

### Synthetics alert

| Key | What it detects | Critical |
|-----|----------------|----------|
| `synthetics_failure` | Any synthetic check failure | any failure |

## Custom alerts

Define alerts not in the catalog via `custom_alerts`:

```hcl
custom_alerts = {
  payment_timeout = {
    name     = "[PROD] Payment Gateway Timeout"
    nrql     = "SELECT count(*) FROM Transaction WHERE appName = 'my-app' AND name LIKE '%Payment%' AND duration > 5"
    operator = "above"
    critical = 10
    warning  = 5
  }
}
```

## Dashboard catalog

| Key | Contents |
|-----|----------|
| `apm_overview` | Error rate, response time, throughput, Apdex, top transactions |
| `infrastructure` | Host CPU, memory, disk |
| `kubernetes` | Pod status, container CPU/memory limits, desired vs ready pods |

```hcl
dashboards = {
  apm_overview   = {}
  infrastructure = { name = "My Custom Dashboard Name" }
}
```

## Synthetic monitors

| Key | Type | Default frequency |
|-----|------|-------------------|
| `ping` | Simple ping | prod: 5m, staging: 15m, dev: 30m |
| `browser` | Browser (scripted) | prod: 5m, staging: 15m, dev: 30m |
| `api` | Scripted API | prod: 5m, staging: 15m, dev: 30m |

```hcl
synthetics = {
  ping    = { uri = "https://my-app.example.com/health" }
  browser = { uri = "https://my-app.example.com" }
}
```

## Notifications

Up to three channels can be wired to the alert policy workflow. Only enabled channels are created.

```hcl
notifications = {
  pagerduty = {
    enabled         = true
    integration_key = var.pagerduty_key   # pass via TF_VAR_pagerduty_key
  }
  slack = {
    enabled    = true
    webhook    = var.slack_webhook         # pass via TF_VAR_slack_webhook
    channel_id = var.slack_channel_id
  }
  email = {
    enabled   = true
    addresses = ["oncall@example.com", "team@example.com"]
  }
}
```

Sensitive values (`integration_key`, `webhook`) should be passed via `TF_VAR_*` environment variables and never committed to version control.

## Outputs

| Name | Description |
|------|-------------|
| `policy_id` | ID of the alert policy |
| `policy_name` | Name of the alert policy |
| `active_alert_keys` | Keys of the alert conditions created |
| `dashboard_ids` | Map of dashboard key → dashboard ID |
| `synthetic_monitor_ids` | Map of synthetic key → monitor ID |

## Versioning

Pin the `?ref=` to a release tag. See [releases](https://github.com/somensari/terraform-newrelic-app/releases) for the full changelog.

```hcl
source = "git::https://github.com/somensari/terraform-newrelic-app.git?ref=v0.1.0"
```
