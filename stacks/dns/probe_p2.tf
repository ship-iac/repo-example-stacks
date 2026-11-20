# Probe M29 P2: plan fails before 2026-11-20T20:48:13Z, passes after.
resource "terraform_data" "probe_p2" {
  lifecycle {
    precondition {
      condition     = var.env != "" && timecmp(plantimestamp(), "2026-11-20T20:48:13Z") > 0
      error_message = "probe p2: before 2026-11-20T20:48:13Z"
    }
  }
}
