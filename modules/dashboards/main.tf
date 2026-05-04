locals {
  apm_widgets = [
    {
      title  = "Error Rate %"
      row    = 1
      column = 1
      width  = 4
      height = 3
      nrql   = "SELECT percentage(count(*), WHERE error IS TRUE) FROM Transaction WHERE appName = '${var.app_name}' TIMESERIES"
      viz    = "viz.line"
    },
    {
      title  = "Response Time (s)"
      row    = 1
      column = 5
      width  = 4
      height = 3
      nrql   = "SELECT average(duration) FROM Transaction WHERE appName = '${var.app_name}' TIMESERIES"
      viz    = "viz.line"
    },
    {
      title  = "Throughput (rpm)"
      row    = 1
      column = 9
      width  = 4
      height = 3
      nrql   = "SELECT rate(count(*), 1 minute) FROM Transaction WHERE appName = '${var.app_name}' TIMESERIES"
      viz    = "viz.line"
    },
    {
      title  = "Apdex"
      row    = 4
      column = 1
      width  = 4
      height = 3
      nrql   = "SELECT apdex(duration, t: 0.4) FROM Transaction WHERE appName = '${var.app_name}' TIMESERIES"
      viz    = "viz.line"
    },
    {
      title  = "Top Transactions by Duration"
      row    = 4
      column = 5
      width  = 8
      height = 3
      nrql   = "SELECT average(duration) FROM Transaction WHERE appName = '${var.app_name}' FACET name LIMIT 10"
      viz    = "viz.bar"
    },
  ]

  infra_widgets = [
    {
      title  = "CPU %"
      row    = 1
      column = 1
      width  = 4
      height = 3
      nrql   = "SELECT average(host.cpuPercent) FROM Metric WHERE apmApplicationNames LIKE '%${var.app_name}%' FACET host.hostname TIMESERIES"
      viz    = "viz.line"
    },
    {
      title  = "Memory Used %"
      row    = 1
      column = 5
      width  = 4
      height = 3
      nrql   = "SELECT average(memoryUsedPercent) FROM SystemSample WHERE apmApplicationNames LIKE '%${var.app_name}%' FACET hostname TIMESERIES"
      viz    = "viz.line"
    },
    {
      title  = "Disk Used %"
      row    = 1
      column = 9
      width  = 4
      height = 3
      nrql   = "SELECT average(diskUsedPercent) FROM StorageSample WHERE apmApplicationNames LIKE '%${var.app_name}%' FACET hostname TIMESERIES"
      viz    = "viz.line"
    },
  ]

  k8s_widgets = [
    {
      title  = "Pod Status"
      row    = 1
      column = 1
      width  = 4
      height = 3
      nrql   = "SELECT count(*) FROM K8sPodSample WHERE deploymentName LIKE '%${var.app_name}%' FACET status"
      viz    = "viz.pie"
    },
    {
      title  = "Container CPU Limit %"
      row    = 1
      column = 5
      width  = 4
      height = 3
      nrql   = "SELECT average((cpuUsedCores / cpuLimitCores) * 100) FROM K8sContainerSample WHERE deploymentName LIKE '%${var.app_name}%' FACET containerName TIMESERIES"
      viz    = "viz.line"
    },
    {
      title  = "Container Memory Limit %"
      row    = 1
      column = 9
      width  = 4
      height = 3
      nrql   = "SELECT average((memoryUsedBytes / memoryLimitBytes) * 100) FROM K8sContainerSample WHERE deploymentName LIKE '%${var.app_name}%' FACET containerName TIMESERIES"
      viz    = "viz.line"
    },
    {
      title  = "Desired vs Ready Pods"
      row    = 4
      column = 1
      width  = 6
      height = 3
      nrql   = "SELECT latest(podsDesired) AS 'Desired', latest(podsReady) AS 'Ready' FROM K8sReplicasetSample WHERE deploymentName LIKE '%${var.app_name}%' FACET deploymentName TIMESERIES"
      viz    = "viz.line"
    },
  ]

  widget_map = {
    apm_overview   = local.apm_widgets
    infrastructure = local.infra_widgets
    kubernetes     = local.k8s_widgets
  }
}

resource "newrelic_one_dashboard" "this" {
  for_each = var.active_dashboards

  account_id = var.account_id
  name       = each.value.name

  page {
    name = each.value.name

    dynamic "widget_line" {
      for_each = [
        for w in local.widget_map[each.key] : w
        if w.viz == "viz.line"
      ]
      content {
        title  = widget_line.value.title
        row    = widget_line.value.row
        column = widget_line.value.column
        width  = widget_line.value.width
        height = widget_line.value.height

        nrql_query {
          account_id = var.account_id
          query      = widget_line.value.nrql
        }
      }
    }

    dynamic "widget_bar" {
      for_each = [
        for w in local.widget_map[each.key] : w
        if w.viz == "viz.bar"
      ]
      content {
        title  = widget_bar.value.title
        row    = widget_bar.value.row
        column = widget_bar.value.column
        width  = widget_bar.value.width
        height = widget_bar.value.height

        nrql_query {
          account_id = var.account_id
          query      = widget_bar.value.nrql
        }
      }
    }

    dynamic "widget_pie" {
      for_each = [
        for w in local.widget_map[each.key] : w
        if w.viz == "viz.pie"
      ]
      content {
        title  = widget_pie.value.title
        row    = widget_pie.value.row
        column = widget_pie.value.column
        width  = widget_pie.value.width
        height = widget_pie.value.height

        nrql_query {
          account_id = var.account_id
          query      = widget_pie.value.nrql
        }
      }
    }
  }
}

resource "newrelic_entity_tags" "dashboard" {
  for_each = var.active_dashboards

  guid = newrelic_one_dashboard.this[each.key].guid

  dynamic "tag" {
    for_each = var.labels
    content {
      key    = tag.key
      values = [tag.value]
    }
  }
}
