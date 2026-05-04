resource "newrelic_synthetics_monitor" "this" {
  for_each = var.active_synthetics

  account_id = var.account_id
  name       = each.value.name
  type       = each.value.type
  period     = each.value.period
  status     = "ENABLED"

  # uri is required for SIMPLE and BROWSER types; optional for SCRIPT_API/SCRIPT_BROWSER
  uri = each.value.uri

  locations_public = ["US_EAST_1", "US_WEST_2", "EU_WEST_1"]

  # Modern runtime for BROWSER type
  dynamic "tag" {
    for_each = each.value.type == "BROWSER" ? [1] : []
    content {
      key    = "runtime"
      values = ["CHROME_BROWSER:100"]
    }
  }

  dynamic "tag" {
    for_each = var.labels
    content {
      key    = tag.key
      values = [tag.value]
    }
  }
}
