# Probe M29 P4: plan fails before 2026-11-20T22:16:48Z, passes after.
resource "terraform_data" "probe_p4" {
  lifecycle {
    precondition {
      condition     = var.env != "" && timecmp(plantimestamp(), "2026-11-20T22:16:48Z") > 0
      error_message = "probe p4: before 2026-11-20T22:16:48Z"
    }
  }
}
