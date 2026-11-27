# Unknown until apply, so the postcondition fails the apply, not the plan.
resource "terraform_data" "fail" {
  input = timestamp()
  lifecycle {
    postcondition {
      condition     = self.output == "never"
      error_message = "m35 acceptance apply-time failure fixture"
    }
  }
}
