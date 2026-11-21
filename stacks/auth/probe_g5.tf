resource "terraform_data" "probe_g5" {
  lifecycle {
    precondition {
      condition     = var.env != "" && timecmp(plantimestamp(), "2026-11-21T09:53:47Z") > 0
      error_message = "Scratch time bomb for an engine live check."
    }
  }
}
