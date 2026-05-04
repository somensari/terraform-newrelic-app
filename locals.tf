locals {
  # Thresholds loosen in non-prod to reduce noise.
  # prod = 1x, staging = 2x, dev = 5x
  env_factor = {
    prod    = 1
    staging = 2
    dev     = 5
  }
  f = local.env_factor[var.environment]

  env_upper = upper(var.environment)

  # Synthetics run more frequently in prod.
  synthetics_period = {
    prod    = "EVERY_5_MINUTES"
    staging = "EVERY_15_MINUTES"
    dev     = "EVERY_30_MINUTES"
  }

  # ─── Alert Catalog ──────────────────────────────────────────────────────────
  # All available alerts. Teams opt-in by key in var.alerts.
  # Thresholds scale with environment factor.

  alert_catalog = {
    # APM — Golden Signals
    error_rate = {
      name              = "[${local.env_upper}] High Error Rate — ${var.app_name}"
      nrql              = "SELECT percentage(count(*), WHERE error IS TRUE) FROM Transaction WHERE appName = '${var.app_name}'"
      operator          = "above"
      critical          = 5 * local.f
      critical_duration = 300
      warning           = 2 * local.f
      warning_duration  = 300
    }
    response_time = {
      name              = "[${local.env_upper}] High Response Time — ${var.app_name}"
      nrql              = "SELECT average(duration) FROM Transaction WHERE appName = '${var.app_name}'"
      operator          = "above"
      critical          = 3 * local.f
      critical_duration = 300
      warning           = 1 * local.f
      warning_duration  = 300
    }
    apdex = {
      name              = "[${local.env_upper}] Low Apdex — ${var.app_name}"
      nrql              = "SELECT apdex(duration, t: 0.4) FROM Transaction WHERE appName = '${var.app_name}'"
      operator          = "below"
      critical          = 0.7
      critical_duration = 300
      warning           = 0.85
      warning_duration  = 300
    }
    throughput = {
      name              = "[${local.env_upper}] Low Throughput — ${var.app_name}"
      nrql              = "SELECT rate(count(*), 1 minute) FROM Transaction WHERE appName = '${var.app_name}'"
      operator          = "below"
      critical          = 1
      critical_duration = 300
      warning           = null
      warning_duration  = null
    }

    # APM — Golden Metrics (entity-scoped, works across apps in the account)
    golden_error_rate = {
      name              = "[${local.env_upper}] Golden Error Rate — ${var.app_name}"
      nrql              = "FROM Metric SELECT count(apm.service.error.count) / count(apm.service.transaction.duration) AS 'Error Rate' WHERE appName = '${var.app_name}'"
      operator          = "above"
      critical          = 5 * local.f
      critical_duration = 300
      warning           = 2 * local.f
      warning_duration  = 300
    }
    golden_response_time = {
      name              = "[${local.env_upper}] Golden Response Time — ${var.app_name}"
      nrql              = "SELECT average(newrelic.goldenmetrics.apm.application.responseTimeMs) FROM Metric WHERE appName = '${var.app_name}'"
      operator          = "above"
      critical          = 3000 * local.f
      critical_duration = 300
      warning           = 1000 * local.f
      warning_duration  = 300
    }
    golden_throughput = {
      name              = "[${local.env_upper}] Golden Low Throughput — ${var.app_name}"
      nrql              = "SELECT average(newrelic.goldenmetrics.apm.application.throughput) FROM Metric WHERE appName = '${var.app_name}'"
      operator          = "below"
      critical          = 1
      critical_duration = 300
      warning           = null
      warning_duration  = null
    }

    # Infrastructure — Host
    host_cpu = {
      name              = "[${local.env_upper}] High Host CPU — ${var.app_name}"
      nrql              = "SELECT average(host.cpuPercent) FROM Metric WHERE apmApplicationNames LIKE '%${var.app_name}%' FACET host.hostname"
      operator          = "above"
      critical          = 90
      critical_duration = 300
      warning           = 75
      warning_duration  = 300
    }
    host_memory = {
      name              = "[${local.env_upper}] High Host Memory — ${var.app_name}"
      nrql              = "SELECT average(memoryUsedPercent) FROM SystemSample WHERE apmApplicationNames LIKE '%${var.app_name}%' FACET hostname"
      operator          = "above"
      critical          = 90
      critical_duration = 300
      warning           = 80
      warning_duration  = 300
    }
    host_disk = {
      name              = "[${local.env_upper}] High Disk Usage — ${var.app_name}"
      nrql              = "SELECT average(diskUsedPercent) FROM StorageSample WHERE apmApplicationNames LIKE '%${var.app_name}%' FACET hostname"
      operator          = "above"
      critical          = 90
      critical_duration = 300
      warning           = 80
      warning_duration  = 300
    }

    # Kubernetes
    k8s_pod_not_ready = {
      name              = "[${local.env_upper}] Pod Not Ready — ${var.app_name}"
      nrql              = "SELECT count(*) FROM K8sPodSample WHERE deploymentName LIKE '%${var.app_name}%' AND isReady = 0 AND status NOT IN ('Succeeded', 'Failed')"
      operator          = "above"
      critical          = 0
      critical_duration = 300
      warning           = null
      warning_duration  = null
    }
    k8s_container_cpu = {
      name              = "[${local.env_upper}] Container CPU Limit — ${var.app_name}"
      nrql              = "SELECT average((cpuUsedCores / cpuLimitCores) * 100) FROM K8sContainerSample WHERE deploymentName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 85
      critical_duration = 300
      warning           = 70
      warning_duration  = 300
    }
    k8s_container_memory = {
      name              = "[${local.env_upper}] Container Memory Limit — ${var.app_name}"
      nrql              = "SELECT average((memoryUsedBytes / memoryLimitBytes) * 100) FROM K8sContainerSample WHERE deploymentName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 90
      critical_duration = 300
      warning           = 80
      warning_duration  = 300
    }
    k8s_replicaset = {
      name              = "[${local.env_upper}] ReplicaSet Missing Pods — ${var.app_name}"
      nrql              = "SELECT max(podsDesired - podsReady) FROM K8sReplicasetSample WHERE deploymentName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 0
      critical_duration = 300
      warning           = null
      warning_duration  = null
    }

    # Synthetics
    synthetics_failure = {
      name              = "[${local.env_upper}] Synthetic Monitor Failure — ${var.app_name}"
      nrql              = "SELECT count(*) FROM SyntheticCheck WHERE result != 'SUCCESS' AND monitorName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 0
      critical_duration = 300
      warning           = null
      warning_duration  = null
    }

    # AWS — Load Balancer / Compute / Data
    aws_alb_5xx = {
      name              = "[${local.env_upper}] ALB 5xx Errors — ${var.app_name}"
      nrql              = "SELECT sum(`aws.applicationelb.HTTPCode_ELB_5XX_Count`) FROM Metric WHERE entityName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 10 * local.f
      critical_duration = 300
      warning           = 5 * local.f
      warning_duration  = 300
    }
    aws_alb_response_time = {
      name              = "[${local.env_upper}] ALB Response Time — ${var.app_name}"
      nrql              = "SELECT average(`aws.applicationelb.TargetResponseTime`) FROM Metric WHERE entityName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 3 * local.f
      critical_duration = 300
      warning           = 1 * local.f
      warning_duration  = 300
    }
    aws_rds_cpu = {
      name              = "[${local.env_upper}] RDS CPU — ${var.app_name}"
      nrql              = "SELECT average(`aws.rds.CPUUtilization`) FROM Metric WHERE entityName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 90
      critical_duration = 300
      warning           = 75
      warning_duration  = 300
    }
    aws_rds_connections = {
      name              = "[${local.env_upper}] RDS Connection Count — ${var.app_name}"
      nrql              = "SELECT average(`aws.rds.DatabaseConnections`) FROM Metric WHERE entityName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 500 * local.f
      critical_duration = 300
      warning           = 400 * local.f
      warning_duration  = 300
    }
    aws_sqs_depth = {
      name              = "[${local.env_upper}] SQS Queue Depth — ${var.app_name}"
      nrql              = "SELECT max(`aws.sqs.ApproximateNumberOfMessagesVisible`) FROM Metric WHERE entityName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 1000 * local.f
      critical_duration = 300
      warning           = 500 * local.f
      warning_duration  = 300
    }
    aws_lambda_errors = {
      name              = "[${local.env_upper}] Lambda Error Rate — ${var.app_name}"
      nrql              = "SELECT sum(`aws.lambda.Errors`) / sum(`aws.lambda.Invocations`) * 100 FROM Metric WHERE entityName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 5 * local.f
      critical_duration = 300
      warning           = 2 * local.f
      warning_duration  = 300
    }
    aws_lambda_duration = {
      name              = "[${local.env_upper}] Lambda Duration — ${var.app_name}"
      nrql              = "SELECT average(`aws.lambda.Duration`) FROM Metric WHERE entityName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 10000 * local.f
      critical_duration = 300
      warning           = 5000 * local.f
      warning_duration  = 300
    }

    # Azure — App Gateway / SQL / Messaging / Functions
    azure_app_gateway_5xx = {
      name              = "[${local.env_upper}] App Gateway 5xx — ${var.app_name}"
      nrql              = "SELECT sum(`azure.network.applicationgateways.FailedRequests`) FROM Metric WHERE entityName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 10 * local.f
      critical_duration = 300
      warning           = 5 * local.f
      warning_duration  = 300
    }
    azure_sql_cpu = {
      name              = "[${local.env_upper}] Azure SQL CPU — ${var.app_name}"
      nrql              = "SELECT average(`azure.sql.servers.databases.cpu_percent`) FROM Metric WHERE entityName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 90
      critical_duration = 300
      warning           = 75
      warning_duration  = 300
    }
    azure_sql_dtu = {
      name              = "[${local.env_upper}] Azure SQL DTU — ${var.app_name}"
      nrql              = "SELECT average(`azure.sql.servers.databases.dtu_consumption_percent`) FROM Metric WHERE entityName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 90
      critical_duration = 300
      warning           = 75
      warning_duration  = 300
    }
    azure_servicebus_depth = {
      name              = "[${local.env_upper}] Service Bus Queue Depth — ${var.app_name}"
      nrql              = "SELECT max(`azure.servicebus.namespaces.ActiveMessages`) FROM Metric WHERE entityName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 1000 * local.f
      critical_duration = 300
      warning           = 500 * local.f
      warning_duration  = 300
    }
    azure_functions_5xx = {
      name              = "[${local.env_upper}] Azure Functions 5xx — ${var.app_name}"
      nrql              = "SELECT sum(`azure.web.sites.Http5xx`) FROM Metric WHERE entityName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 10 * local.f
      critical_duration = 300
      warning           = 5 * local.f
      warning_duration  = 300
    }

    # GCP — Load Balancer / Cloud SQL / Pub/Sub / Functions / GKE
    gcp_lb_5xx = {
      name              = "[${local.env_upper}] GCP LB 5xx — ${var.app_name}"
      nrql              = "SELECT sum(`gcp.loadbalancing.googleapis.com.https.request_count`) FROM Metric WHERE entityName LIKE '%${var.app_name}%' AND response_code_class = 500"
      operator          = "above"
      critical          = 10 * local.f
      critical_duration = 300
      warning           = 5 * local.f
      warning_duration  = 300
    }
    gcp_cloudsql_cpu = {
      name              = "[${local.env_upper}] Cloud SQL CPU — ${var.app_name}"
      nrql              = "SELECT average(`gcp.cloudsql.googleapis.com.database.cpu.utilization`) * 100 FROM Metric WHERE entityName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 90
      critical_duration = 300
      warning           = 75
      warning_duration  = 300
    }
    gcp_pubsub_depth = {
      name              = "[${local.env_upper}] Pub/Sub Undelivered Messages — ${var.app_name}"
      nrql              = "SELECT max(`gcp.pubsub.googleapis.com.subscription.num_undelivered_messages`) FROM Metric WHERE entityName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 1000 * local.f
      critical_duration = 300
      warning           = 500 * local.f
      warning_duration  = 300
    }
    gcp_functions_errors = {
      name              = "[${local.env_upper}] Cloud Functions Errors — ${var.app_name}"
      nrql              = "SELECT sum(`gcp.cloudfunctions.googleapis.com.function.execution_count`) FROM Metric WHERE entityName LIKE '%${var.app_name}%' AND status != 'ok'"
      operator          = "above"
      critical          = 10 * local.f
      critical_duration = 300
      warning           = 5 * local.f
      warning_duration  = 300
    }
    gcp_gke_node_cpu = {
      name              = "[${local.env_upper}] GKE Node CPU — ${var.app_name}"
      nrql              = "SELECT average(`gcp.kubernetes.googleapis.com.node.cpu.allocatable_utilization`) * 100 FROM Metric WHERE entityName LIKE '%${var.app_name}%'"
      operator          = "above"
      critical          = 90
      critical_duration = 300
      warning           = 75
      warning_duration  = 300
    }
  }

  # Merge catalog defaults with team overrides; only keys team declared are active.
  catalog_alerts = {
    for k, override in var.alerts :
    k => {
      name              = coalesce(override.name, local.alert_catalog[k].name)
      nrql              = coalesce(override.nrql, local.alert_catalog[k].nrql)
      operator          = coalesce(override.operator, local.alert_catalog[k].operator)
      critical          = coalesce(override.critical, local.alert_catalog[k].critical)
      critical_duration = coalesce(override.critical_duration, local.alert_catalog[k].critical_duration)
      warning           = try(coalesce(override.warning, local.alert_catalog[k].warning), null)
      warning_duration  = try(coalesce(override.warning_duration, local.alert_catalog[k].warning_duration), null)
    }
    if contains(keys(local.alert_catalog), k) && coalesce(override.enabled, true)
  }

  # Final set passed to the alerts sub-module: catalog (with overrides) + custom
  active_alerts = merge(local.catalog_alerts, {
    for k, v in var.custom_alerts : k => v if v.enabled
  })

  # ─── Dashboard Catalog ──────────────────────────────────────────────────────

  dashboard_catalog = {
    apm_overview = {
      name = "[${local.env_upper}] APM Overview — ${var.app_name}"
    }
    infrastructure = {
      name = "[${local.env_upper}] Infrastructure — ${var.app_name}"
    }
    kubernetes = {
      name = "[${local.env_upper}] Kubernetes — ${var.app_name}"
    }
  }

  active_dashboards = {
    for k, override in var.dashboards :
    k => {
      name = coalesce(override.name, local.dashboard_catalog[k].name)
    }
    if contains(keys(local.dashboard_catalog), k) && coalesce(override.enabled, true)
  }

  # ─── Synthetics Catalog ─────────────────────────────────────────────────────

  synthetics_catalog = {
    ping = {
      name   = "[${local.env_upper}] Ping — ${var.app_name}"
      type   = "SIMPLE"
      period = local.synthetics_period[var.environment]
      uri    = null
    }
    browser = {
      name   = "[${local.env_upper}] Browser — ${var.app_name}"
      type   = "BROWSER"
      period = local.synthetics_period[var.environment]
      uri    = null
    }
    api = {
      name   = "[${local.env_upper}] Scripted API — ${var.app_name}"
      type   = "SCRIPT_API"
      period = local.synthetics_period[var.environment]
      uri    = null
    }
  }

  active_synthetics = {
    for k, override in var.synthetics :
    k => {
      name   = coalesce(override.name, local.synthetics_catalog[k].name)
      type   = local.synthetics_catalog[k].type
      period = coalesce(override.period, local.synthetics_catalog[k].period)
      uri    = override.uri
    }
    if contains(keys(local.synthetics_catalog), k) && coalesce(override.enabled, true)
  }
}
