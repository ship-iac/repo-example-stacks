# Probe M29 P2b: plan fails before 2026-11-20T21:49:31Z, passes after.
resource "terraform_data" "probe_p2" {
  lifecycle {
    precondition {
      condition     = var.env != "" && timecmp(plantimestamp(), "2026-11-20T21:49:31Z") > 0
      error_message = "probe p2: before 2026-11-20T21:49:31Z"
    }
  }
}
